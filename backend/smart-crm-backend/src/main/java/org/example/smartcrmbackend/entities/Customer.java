package org.example.smartcrmbackend.entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import org.example.smartcrmbackend.enums.CustomerState;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "customers")
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class Customer {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String firstName;
    private String lastName;
    private String email;
    private String phone;
    private String address;
    @Enumerated(EnumType.STRING)
    @Column(name = "customer_state", nullable = false, length = 20)
    private CustomerState customerState = CustomerState.ACTIF;
    @OneToMany(mappedBy = "customer")
    @Builder.Default
    private List<CustomerScore> customerScores = new ArrayList<>();
    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
