package org.example.smartcrmbackend.entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import com.fasterxml.jackson.annotation.JsonIgnore;
import org.example.smartcrmbackend.enums.CampaignStatus;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "campaigns")
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class Campaign {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;
    private String subject;

    @Column(nullable = false)
    private String body;

    @Column(name = "scheduled_at")
    private LocalDateTime scheduledAt;

    @ManyToOne(optional = false)
    @JoinColumn(name = "segment_id", nullable = false)
    private Segment segment;

    @OneToMany(mappedBy = "campaign")
    @JsonIgnore
    @Builder.Default
    private List<EmailLog> emailLogs = new ArrayList<>();

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    private CampaignStatus status;

}
