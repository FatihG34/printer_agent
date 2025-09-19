package com.alpidiprinteragent.alpidiprinteragent;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class AlpidiprinteragentApplication {

	public static void main(String[] args) {
		SpringApplication.run(AlpidiprinteragentApplication.class, args);
	}

}
