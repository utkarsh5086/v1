//
//  Models.swift
//  test_proj
//
//  Created by Utkarsh Sharma on 1/30/26.
//
import Foundation

// The full response from your API
struct ElectionResponse: Codable {
    let address: String
    let location: Location
    let elections: [Election]
}

// Location info in the response
struct Location: Codable {
    let state: String?
    let county: String?
    let city: String?
}

// Each election object
struct Election: Codable {
    let id: Int
    let name: String
    let date: String
    let start_time: String?
    let end_time: String?
    let level: String
    let state: String?
    let county: String?
    let city: String?
    let races_count: Int?
    let measures: Int?
}


struct ElectionDetailResponse: Codable {
    let election: Election
    let races: [Race]
    let measures: [Measure]
}

struct Race: Codable, Identifiable {
    let id: Int
    let term: Int?
    let race_name: String
    let num_candidates: Int
    let candidates: [Candidate]
}

struct Candidate: Codable, Identifiable {
    let id: Int
    let name: String
    let party: String?
    let description: String?
}

struct Measure: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String
    let yes_description: String?
    let no_description: String?
}

