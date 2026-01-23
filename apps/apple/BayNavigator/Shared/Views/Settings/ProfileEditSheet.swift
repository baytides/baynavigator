import SwiftUI
import BayNavigatorCore

/// Sheet for editing the main user profile without going through onboarding wizard
struct ProfileEditSheet: View {
    @Environment(UserPrefsViewModel.self) private var userPrefsVM
    @Environment(\.dismiss) private var dismiss

    // Form state
    @State private var firstName: String = ""
    @State private var locationInput: String = ""
    @State private var city: String?
    @State private var zipCode: String?
    @State private var county: String?
    @State private var birthYear: Int?
    @State private var isMilitaryOrVeteran: Bool = false
    @State private var selectedQualifications: Set<String> = []
    @State private var selectedColorIndex: Int = 0

    // Location state
    @State private var locationSuggestions: [String] = []
    @State private var locationError: String?
    @State private var isGpsLoading = false
    @State private var locationService = LocationService()

    @FocusState private var focusedField: Field?

    enum Field {
        case name
        case location
    }

    private let qualificationOptions: [(id: String, title: String, icon: String)] = [
        ("military", "Veteran or Military", "shield.checkered"),
        ("lgbtq", "LGBTQ+", "person.3.fill"),
        ("immigrant", "Immigrant", "globe.americas.fill"),
        ("first-responder", "First Responder", "flame.fill"),
        ("educator", "Teacher or Educator", "book.fill"),
        ("unemployed", "Looking for work", "briefcase.fill"),
        ("public-assistance", "Public assistance", "giftcard.fill"),
        ("student", "Student", "graduationcap.fill"),
        ("disability", "Disability", "figure.roll"),
        ("caregiver", "Caregiver", "heart.fill")
    ]

    var body: some View {
        NavigationStack {
            Form {
                nameSection
                locationSection
                birthYearSection
                profileColorSection
                qualificationsSection
            }
            .navigationTitle("Edit Profile")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                loadCurrentProfile()
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - View Components

    private var nameSection: some View {
        Section("Name") {
            TextField("Your first name", text: $firstName)
                .textContentType(.givenName)
                .focused($focusedField, equals: .name)
                #if os(iOS)
                .textInputAutocapitalization(.words)
                #endif
        }
    }

    private var locationSection: some View {
        Section {
            HStack(spacing: 12) {
                TextField("City or ZIP code", text: $locationInput)
                    .focused($focusedField, equals: .location)
                    #if os(iOS)
                    .textInputAutocapitalization(.words)
                    #endif
                    .onChange(of: locationInput) { _, newValue in
                        handleLocationInput(newValue)
                    }

                Button {
                    detectLocation()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.appPrimary)
                            .frame(width: 36, height: 36)

                        if isGpsLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "location.fill")
                                .font(.caption)
                                .foregroundStyle(.white)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(isGpsLoading)
            }

            if !locationSuggestions.isEmpty {
                ForEach(locationSuggestions, id: \.self) { suggestion in
                    Button {
                        selectLocationSuggestion(suggestion)
                    } label: {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(Color.appPrimary)
                            Text(suggestion)
                            Spacer()
                        }
                    }
                }
            }

            if let detectedCounty = county {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.appSuccess)

                    Text(city ?? countyIdToDisplayName(detectedCounty))
                        .font(.subheadline)
                        .foregroundStyle(Color.appSuccess)
                }
            }

            if let error = locationError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        } header: {
            Text("Location")
        } footer: {
            Text("Enter your city or ZIP code to find programs in your area.")
        }
    }

    private var birthYearSection: some View {
        Section {
            let currentYear = Calendar.current.component(.year, from: Date())
            Picker("Birth Year", selection: Binding(
                get: { birthYear ?? (currentYear - 30) },
                set: { birthYear = $0 }
            )) {
                Text("Not set").tag(Optional<Int>.none)
                ForEach(((currentYear - 104)...(currentYear - 18)).reversed(), id: \.self) { year in
                    Text(String(year)).tag(Optional(year))
                }
            }
            .pickerStyle(.menu)

            if let year = birthYear {
                let age = currentYear - year
                Text("Age: \(age) years old")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Birth Year")
        } footer: {
            Text("Used to find age-specific programs.")
        }
    }

    private var profileColorSection: some View {
        Section("Profile Color") {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 44), spacing: 12)
            ], spacing: 12) {
                ForEach(Array(UserPrefsViewModel.profileColors.enumerated()), id: \.offset) { index, color in
                    profileColorButton(index: index, color: color)
                }
            }
            .padding(.vertical, 8)
        }
    }

    private func profileColorButton(index: Int, color: Color) -> some View {
        Button {
            selectedColorIndex = index
            #if os(iOS)
            HapticManager.impact(.light)
            #endif
        } label: {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 44, height: 44)

                if selectedColorIndex == index {
                    Image(systemName: "checkmark")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                }
            }
            .overlay(
                Circle()
                    .stroke(selectedColorIndex == index ? Color.white : Color.clear, lineWidth: 3)
            )
            .shadow(
                color: selectedColorIndex == index ? color.opacity(0.5) : .clear,
                radius: 6,
                x: 0,
                y: 2
            )
        }
        .buttonStyle(.plain)
    }

    private var qualificationsSection: some View {
        Section {
            ForEach(qualificationOptions, id: \.id) { option in
                qualificationRow(option: option)
            }
        } header: {
            Text("About You")
        } footer: {
            Text("Select all that apply to find more relevant programs.")
        }
    }

    private func qualificationRow(option: (id: String, title: String, icon: String)) -> some View {
        let isSelected = option.id == "military"
            ? isMilitaryOrVeteran
            : selectedQualifications.contains(option.id)

        return Button {
            toggleQualification(option.id)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: option.icon)
                    .font(.body)
                    .foregroundStyle(isSelected ? Color.appPrimary : .secondary)
                    .frame(width: 24)

                Text(option.title)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.appPrimary : .secondary)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func loadCurrentProfile() {
        firstName = userPrefsVM.firstName ?? ""
        city = userPrefsVM.city
        zipCode = userPrefsVM.zipCode
        county = userPrefsVM.selectedCounty
        birthYear = userPrefsVM.birthYear
        isMilitaryOrVeteran = userPrefsVM.isMilitaryOrVeteran ?? false
        selectedQualifications = Set(userPrefsVM.qualifications)
        selectedColorIndex = userPrefsVM.profileColorIndex

        // Set location input
        if let zip = zipCode, !zip.isEmpty {
            locationInput = zip
        } else if let cityName = city, !cityName.isEmpty {
            locationInput = cityName
        }
    }

    private func handleLocationInput(_ input: String) {
        guard !input.isEmpty else {
            locationError = nil
            county = nil
            city = nil
            zipCode = nil
            locationSuggestions = []
            return
        }

        // Get suggestions if not a ZIP code
        if !LocationLookup.isZipCodeFormat(input) {
            locationSuggestions = LocationLookup.getSuggestions(for: input, limit: 5)
        } else {
            locationSuggestions = []
        }

        // Try to look up county
        if let countyName = LocationLookup.lookupCounty(input) {
            let countyId = countyNameToId(countyName)

            var cityName = input
            var foundZipCode: String?

            if LocationLookup.isZipCodeFormat(input) {
                foundZipCode = input
                if let foundCity = LocationLookup.zipToCity[input] {
                    cityName = foundCity
                }
            }

            county = countyId
            city = cityName
            zipCode = foundZipCode
            locationError = nil
            locationSuggestions = []
            #if os(iOS)
            HapticManager.impact(.light)
            #endif
        } else if input.count >= 3 {
            locationError = "City or ZIP not found in Bay Area"
            county = nil
            zipCode = nil
        }
    }

    private func selectLocationSuggestion(_ suggestion: String) {
        locationInput = suggestion
        handleLocationInput(suggestion)
        focusedField = nil
    }

    private func detectLocation() {
        isGpsLoading = true
        locationError = nil

        locationService.getCurrentLocation()

        Task {
            for _ in 0..<30 {
                try? await Task.sleep(nanoseconds: 100_000_000)
                if !locationService.isLoading {
                    break
                }
            }

            await MainActor.run {
                isGpsLoading = false

                if let detectedCounty = locationService.currentCounty {
                    let countyId = countyNameToId(detectedCounty)
                    county = countyId
                    city = detectedCounty
                    locationInput = detectedCounty
                    locationError = nil
                    #if os(iOS)
                    HapticManager.impact(.light)
                    #endif
                } else if let error = locationService.error {
                    locationError = error
                } else {
                    locationError = "Could not detect location."
                }
            }
        }
    }

    private func toggleQualification(_ id: String) {
        #if os(iOS)
        HapticManager.impact(.light)
        #endif
        if id == "military" {
            isMilitaryOrVeteran.toggle()
        } else if selectedQualifications.contains(id) {
            selectedQualifications.remove(id)
        } else {
            selectedQualifications.insert(id)
        }
    }

    private func save() {
        Task {
            await userPrefsVM.savePreferences(
                firstName: firstName.isEmpty ? nil : firstName,
                city: city,
                zipCode: zipCode,
                county: county,
                birthYear: birthYear,
                isMilitaryOrVeteran: isMilitaryOrVeteran ? true : nil,
                qualifications: Array(selectedQualifications),
                groups: userPrefsVM.selectedGroups,
                profileColorIndex: selectedColorIndex
            )

            await MainActor.run {
                #if os(iOS)
                HapticManager.impact(.medium)
                #endif
                dismiss()
            }
        }
    }

    // MARK: - Helpers

    private func countyNameToId(_ countyName: String) -> String {
        countyName.lowercased().replacingOccurrences(of: " ", with: "-")
    }

    private func countyIdToDisplayName(_ countyId: String) -> String {
        countyId.split(separator: "-")
            .map { String($0).capitalized }
            .joined(separator: " ")
    }
}

#Preview {
    ProfileEditSheet()
        .environment(UserPrefsViewModel())
}
