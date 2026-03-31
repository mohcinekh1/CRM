package org.example.smartcrmbackend.entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import com.fasterxml.jackson.annotation.JsonIgnore;

import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "segments")
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class Segment {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;
    private String description;
    private String criteria;

    @ManyToMany(mappedBy = "segments")
    @JsonIgnore
    @Builder.Default
    private List<Customer> customers = new ArrayList<>();

    @OneToMany(mappedBy = "segment")
    @JsonIgnore
    @Builder.Default
    private List<Campaign> campaigns = new ArrayList<>();
}
