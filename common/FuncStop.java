import java.io.IOException;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;

public class FuncStop {

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

        try (Rcon rcon = new Rcon(host, port, password, timeoutMillis)) {
            AtomicInteger remaining = new AtomicInteger(countdownSeconds);
            final AtomicReference<CompletableFuture<String>> saveAllFutureRef = new AtomicReference<>();

            try {
                CompletableFuture<String> saveAllFuture = rcon.sendCommand("save-all");
                saveAllFutureRef.set(saveAllFuture);
                saveAllFuture.whenComplete((response, error) -> {
                    if (error != null) {
                        System.err.println("save-all failed: " + error.getMessage());
                    } else {
                        System.out.println("save-all response: " + response);
                    }
                });
            } catch (IOException e) {
                System.err.println("save-all send failed: " + e.getMessage());
                CompletableFuture<String> failedFuture = new CompletableFuture<>();
                failedFuture.completeExceptionally(e);
                saveAllFutureRef.set(failedFuture);
            }

            ScheduledFuture<?> countdownHandle = mainScheduler.scheduleAtFixedRate(() -> {
                if (stopSignal.isDone()) {
                    return;
                }

                int seconds = remaining.getAndDecrement();
                if (seconds <= 0) {
                    Rcon.sendSyncCommand(rcon, "stop", stopSignal, "stop response:", saveAllFutureRef.get(), true);
                    return;
                }

                if (seconds % 30 == 0 || seconds <= 10) {
                    Rcon.sendAsyncCommand(rcon, "say Server will stop in " + seconds + " seconds.", stopSignal, "say response:", false);
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