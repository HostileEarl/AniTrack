//
//  FieldsView.swift
//  AniTrack — SCREEN 2
//
//  Searching and sorting are done by the controller, so the same rules apply
//  anywhere a list of fields appears.
//

import SwiftUI

struct FieldsView: View {

    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var data: FarmDataController

    @State private var search: String = ""

    private var viewer: ViewerContext {
        return ViewerContext(user: auth.currentUser)
    }

    private var fields: [Parcel] {
        return data.parcels(matching: search, for: viewer)
    }

    var body: some View {
        NavigationStack {
            Group {
                if fields.isEmpty {
                    EmptyStateView(symbolName: "magnifyingglass",
                                   title: "No fields match that search",
                                   message: "Try a barangay name like Bantug, or a crop like Rice.")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(AppTheme.canvas)
                } else {
                    List {
                        Section {
                            ForEach(fields) { parcel in
                                NavigationLink(value: AppRoute.field(parcel.id)) {
                                    ParcelRow(parcel: parcel)
                                }
                            }
                        } header: {
                            Text("Fields with problems are shown first")
                                .font(.system(size: 12))
                                .textCase(nil)
                                .foregroundStyle(AppTheme.muted)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .farmBackground()
                }
            }
            .navigationTitle("Fields")
            .toolbar {
                if viewer.permissions.isReadOnly {
                    ToolbarItem(placement: .navigationBarTrailing) { ReadOnlyTag() }
                }
            }
            .navigationDestination(for: AppRoute.self) { route in
                RouteDestination(route: route)
            }
            .searchable(text: $search, prompt: "Search field, barangay or crop")
        }
    }
}

#Preview {
    FieldsView()
        .environmentObject(AuthController.previewSignedIn())
        .environmentObject(FarmDataController.preview)
}
