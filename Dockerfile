# --- Stage 1: Extract layers (Requires a shell/JDK) ---
FROM eclipse-temurin:21-jdk-alpine AS builder
WORKDIR /application
ARG JAR_FILE=target/spring-boot-web.jar
COPY ${JAR_FILE} application.jar
#this command list all the files needed in runner stage(final stage)
RUN java -Djarmode=layertools -jar application.jar extract

# --- Stage 2: Final minimal production image (Distroless) ---
# gcr.io/distroless/java21-debian12 provides the Java 21 runtime without a shell
FROM gcr.io/distroless/java21-debian12
WORKDIR /application

# Copy the extracted layers from the builder stage(list of files needed in runner stage)
COPY --from=builder /application/dependencies/ ./
COPY --from=builder /application/spring-boot-loader/ ./
COPY --from=builder /application/snapshot-dependencies/ ./
COPY --from=builder /application/application/ ./

# Distroless images automatically configure and run as a non-root 'nonroot' user (UID 65532)
USER nonroot:nonroot

EXPOSE 8080

# Execute using the JarLauncher
ENTRYPOINT ["java", "org.springframework.boot.loader.launch.JarLauncher"]
