//
//  MeasureDetailView.swift
//  test_proj
//
//  Created by Utkarsh Sharma on 1/31/26.
//
import SwiftUI

struct MeasureDetailView: View {
    let measure: Measure

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                Text(measure.title)
                    .font(.title)
                    .bold()

                Text(measure.description)
                    .font(.body)

                Divider()

                if let yes = measure.yes_description {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Yes Vote")
                            .font(.headline)
                            .foregroundColor(.green)
                        Text(yes)
                    }
                }

                if let no = measure.no_description {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("No Vote")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text(no)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Ballot Measure")
        .navigationBarTitleDisplayMode(.inline)
    }
}
