package org.example.smartcrmbackend.entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import org.hibernate.annotations.CreationTimestamp;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.example.smartcrmbackend.enums.ScoreLabel;

import java.time.LocalDateTime;

@Entity
@Table(name = "customer_scores")
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class CustomerScore {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(nullable = false)
    private Integer score;
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private ScoreLabel label;
    @CreationTimestamp
    @Column(name = "computed_at", nullable = false, updatable = false)
    private LocalDateTime computedAt;
    @ManyToOne(optional = false)
    @JoinColumn(name = "customer_id", nullable = false)
    private Customer customer;
}
