import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.net.SocketTimeoutException;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

public class FuncStop implements AutoCloseable {

    private static final int DATA_BUFFSIZE = 1460;
    private final Socket socket;
    private final OutputStream out;
    private final InputStream in;
    private final AtomicInteger requestId = new AtomicInteger(1);
    private final Map<Integer, PendingResponse> pendingResponses = new ConcurrentHashMap<>();
    private final ExecutorService readerExecutor = Executors.newSingleThreadExecutor(r -> new Thread(r, "MinecraftRcon-Reader"));
    private final ScheduledExecutorService scheduler = Executors.newSingleThreadScheduledExecutor(r -> new Thread(r, "MinecraftRcon-Scheduler"));
    private final Object sendLock = new Object();
    private final long packetCompleteDelayMillis = 200;
    private volatile boolean connectionAlive = true;
    private int timeoutMillis;

    public FuncStop(String host, int port, String password) throws IOException {
        this(host, port, password, 0);
    }

    public FuncStop(String host, int port, String password, int timeoutMillis) throws IOException {
        this.timeoutMillis = timeoutMillis;
        this.socket = new Socket();
        this.socket.connect(new InetSocketAddress(host, port), Math.max(timeoutMillis, 5000)); // connection timeout at least 5s
        if (timeoutMillis > 0) {
            this.socket.setSoTimeout(timeoutMillis);
        }
        this.out = socket.getOutputStream();
        this.in = socket.getInputStream();

        // ログイン処理 (Type 3)
        if (!authenticate(password)) {
            throw new IOException("RCON authentication failed.");
        }

        startReader();
    }

    public void setTimeoutMillis(int timeoutMillis) throws IOException {
        this.timeoutMillis = timeoutMillis;
        if (timeoutMillis > 0) {
            this.socket.setSoTimeout(timeoutMillis);
        } else {
            this.socket.setSoTimeout(0); // block
        }
    }

    private boolean authenticate(String password) throws IOException {
        int id = requestId.getAndIncrement();
        sendPacket(id, 3, password);
        
        // レスポンスの確認
        byte[] response;
        try {
            response = readPacket();
        } catch (SocketTimeoutException e) {
            throw new IOException("RCON authentication timed out after " + timeoutMillis + " ms", e);
        }

        ByteBuffer buffer = ByteBuffer.wrap(response).order(ByteOrder.LITTLE_ENDIAN);
        buffer.getInt(); // Lengthをスキップ
        int responseId = buffer.getInt();
        
        // 認証失敗時はIDが-1で返ってくる
        return responseId == id;
    }

    public CompletableFuture<String> sendCommand(String command) throws IOException {
        int id = requestId.getAndIncrement();
        CompletableFuture<String> future = new CompletableFuture<>();
        PendingResponse pending = new PendingResponse(future);
        pendingResponses.put(id, pending);

        try {
            sendPacket(id, 2, command);
        } catch (IOException e) {
            pendingResponses.remove(id);
            throw e;
        }

        pending.timeoutTask = scheduler.schedule(() -> failPendingRequest(id, new IOException("RCON command response timed out after " + timeoutMillis + " ms")), timeoutMillis, TimeUnit.MILLISECONDS);
        return future;
    }

    private void startReader() {
        readerExecutor.submit(() -> {
            while (connectionAlive && !socket.isClosed() && !Thread.currentThread().isInterrupted()) {
                try {
                    byte[] response = readPacket();
                    handlePacket(response);
                } catch (SocketTimeoutException e) {
                    // タイムアウトは単なる読み取りタイミング
                } catch (IOException e) {
                    connectionAlive = false;
                    failAllPending(e);
                    break;
                }
            }
        });
    }

    private void handlePacket(byte[] response) {
        ByteBuffer buffer = ByteBuffer.wrap(response).order(ByteOrder.LITTLE_ENDIAN);
        int length = buffer.getInt();
        int responseId = buffer.getInt();
        int type = buffer.getInt();
        // TODO: 分割レスポンスで帰ってきた場合の対処をする
        int payloadLength = length - 10; // ID(4)+Type(4)+Null(1)+Padding(1)
        if (payloadLength < 0) {
            return;
        }

        byte[] payload = new byte[payloadLength];
        buffer.get(payload);
        String payloadText = new String(payload, StandardCharsets.UTF_8);

        PendingResponse pending = pendingResponses.get(responseId);
        if (pending == null) {
            return;
        }

        synchronized (pending) {
            pending.builder.append(payloadText);
            if (pending.completionTask != null) {
                pending.completionTask.cancel(false);
            }
            pending.completionTask = scheduler.schedule(() -> completePendingRequest(responseId), packetCompleteDelayMillis, TimeUnit.MILLISECONDS);
        }
    }

    private void completePendingRequest(int responseId) {
        PendingResponse pending = pendingResponses.remove(responseId);
        if (pending == null) {
            return;
        }

        if (pending.timeoutTask != null) {
            pending.timeoutTask.cancel(false);
        }
        if (!pending.future.isDone()) {
            pending.future.complete(pending.builder.toString().trim());
        }
    }

    private void failPendingRequest(int responseId, Throwable cause) {
        PendingResponse pending = pendingResponses.remove(responseId);
        if (pending == null) {
            return;
        }

        if (pending.completionTask != null) {
            pending.completionTask.cancel(false);
        }
        if (!pending.future.isDone()) {
            pending.future.completeExceptionally(cause);
        }
    }

    private void failAllPending(Throwable cause) {
        for (Integer id : pendingResponses.keySet()) {
            failPendingRequest(id, cause);
        }
    }

    private static class PendingResponse {
        final CompletableFuture<String> future;
        final StringBuilder builder = new StringBuilder();
        volatile ScheduledFuture<?> completionTask;
        volatile ScheduledFuture<?> timeoutTask;

        PendingResponse(CompletableFuture<String> future) {
            this.future = future;
        }
    }

    private void sendPacket(int id, int type, String payload) throws IOException {
        byte[] body = payload.getBytes(StandardCharsets.UTF_8);
        int length = body.length + 10;

        ByteBuffer buffer = ByteBuffer.allocate(length + 4);
        buffer.order(ByteOrder.LITTLE_ENDIAN);
        buffer.putInt(length);
        buffer.putInt(id);
        buffer.putInt(type);
        buffer.put(body);
        buffer.put((byte) 0); // Payload null terminator
        buffer.put((byte) 0); // Pad

        synchronized (sendLock) {
            out.write(buffer.array());
            out.flush();
        }
    }

    private byte[] readPacket() throws IOException {
        byte[] header = new byte[4];
        int ret = in.read(header);
        if (ret != 4) {
            connectionAlive = false;
            throw new IOException("Failed to read packet length.");
        }
        
        int length = ByteBuffer.wrap(header).order(ByteOrder.LITTLE_ENDIAN).getInt();
        if (length < 0 || length > DATA_BUFFSIZE) {
            // Invalid size, clean incoming data
            netCleanIncoming(length);
            throw new IOException("Invalid packet size: " + length);
        }
        
        byte[] data = new byte[length];
        
        int totalRead = 0;
        while (totalRead < length) {
            ret = in.read(data, totalRead, length - totalRead);
            if (ret == -1) {
                connectionAlive = false;
                throw new IOException("Connection closed prematurely.");
            }
            totalRead += ret;
        }

        // 扱いやすいようにLengthも含めたバッファを返す
        ByteBuffer fullPacket = ByteBuffer.allocate(length + 4).order(ByteOrder.LITTLE_ENDIAN);
        fullPacket.putInt(length);
        fullPacket.put(data);
        return fullPacket.array();
    }

    private void netCleanIncoming(int size) throws IOException {
        if (size <= 0) return;
        int actualSize = Math.min(size, DATA_BUFFSIZE);
        byte[] tmp = new byte[actualSize];
        int ret = in.read(tmp);
        if (ret == 0) {
            connectionAlive = false;
        }
    }

    @Override
    public void close() throws IOException {
        connectionAlive = false;
        readerExecutor.shutdownNow();
        scheduler.shutdownNow();
        socket.close();
        failAllPending(new IOException("RCON connection closed."));
    }

    // TODO:send(同期)も必要
    private static void sendAsyncCommand(FuncStop rcon, String command, CompletableFuture<Void> stopSignal, String logPrefix) {
        if (stopSignal.isDone()) {
            return;
        }

        CompletableFuture<String> future;
        try {
            future = rcon.sendCommand(command);
        } catch (IOException e) {
            System.err.println(logPrefix + " send failed: " + e.getMessage());
            stopSignal.complete(null);
            return;
        }

        future.whenComplete((response, error) -> {
            if (stopSignal.isDone()) {
                return;
            }

            if (error != null) {
                System.err.println(logPrefix + " failed: " + error.getMessage());
                stopSignal.complete(null);
            } else {
                System.out.println(logPrefix + " " + response);
            }
        });
    }

    public static void main(String[] args) {
        if(args.length < 3) {
            System.out.println("Usage: java FuncStop <host> <port> <password> [timeoutMillis] [countdownSeconds]");
            return;
        }
        String host = args[0];
        int port = Integer.parseInt(args[1]);
        String password = args[2];
        int timeoutMillis = args.length >= 4 ? Integer.parseInt(args[3]) : 50000;
        int countdownSeconds = args.length >= 5 ? Integer.parseInt(args[4]) : 60;
        ScheduledExecutorService mainScheduler = Executors.newSingleThreadScheduledExecutor(r -> new Thread(r, "MinecraftRcon-MainScheduler"));
        CompletableFuture<Void> stopSignal = new CompletableFuture<>();

        try (FuncStop rcon = new FuncStop(host, port, password, timeoutMillis)) {
            // 最初の save-all を非同期送信
            sendAsyncCommand(rcon, "save-all", stopSignal, "save-all response:");

            // TODO:最初に何秒後に実行するかを登録しておかないと長時間のウェイトをかけた時に時間がズレるので対照が必要
            AtomicInteger remaining = new AtomicInteger(countdownSeconds);
            ScheduledFuture<?> countdownHandle = mainScheduler.scheduleAtFixedRate(() -> {
                if (stopSignal.isDone()) {
                    return;
                }

                int seconds = remaining.getAndDecrement();
                if (seconds <= 0) {
                    //TODO: STOPは同期的かつタイムアウトなしに受け取らないとワールドが破損する
                    sendAsyncCommand(rcon, "stop", stopSignal, "stop response:");
                    return;
                }

                if (seconds % 30 == 0 || seconds <= 10) {
                    sendAsyncCommand(rcon, "say Server will stop in " + seconds + " seconds.", stopSignal, "say response:");
                }
            }, 1, 1, TimeUnit.SECONDS);

            stopSignal.whenComplete((ignored, error) -> countdownHandle.cancel(false));
            stopSignal.join();
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            mainScheduler.shutdownNow();
        }
    }
}