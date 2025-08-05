package com.example.hw;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.web.servlet.function.HandlerFunction;
import org.springframework.web.servlet.function.RouterFunction;
import org.springframework.web.servlet.function.ServerRequest;
import org.springframework.web.servlet.function.ServerResponse;

import java.util.Map;

import static org.springframework.web.servlet.function.RouterFunctions.route;

@SpringBootApplication
public class HwApplication {

    public static void main(String[] args) {
        SpringApplication.run(HwApplication.class, args);
    }

    @Bean
    RouterFunction<ServerResponse> http(@Value("${MESSAGE:Hello, world}") String message) {
        return route()
                .GET("/", _ -> ServerResponse
                        .ok()
                        .body(Map.of("message", message))
                )
                .build();
    }
}
