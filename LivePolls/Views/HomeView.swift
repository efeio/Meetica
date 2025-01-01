//
//  HomeView.swift
//  LivePolls
//
//  Created by Efe Koç on 09/07/23.
//

import SwiftUI
import FirebaseAuth

struct HomeView: View {
    
    @Bindable var vm = HomeViewModel()
    @State private var selectedDate: Date = Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 1))!
    @State private var selectedLocation: String = "On-Site"
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date()
    
    @State private var isLoggedOut = false  // Kullanıcı çıkışı için bir state
    @State private var navigateToLogin = false // Login sayfasına yönlendirme için state
    
    var body: some View {
        NavigationStack {
            List {
                existingPollSection
                livePollsSection
                createPollsSection
                addOptionsSection
                timePickerSection
                calendarViewSection
                logoutSection
            }
            .scrollDismissesKeyboard(.interactively)
            .alert("Hata", isPresented: .constant(vm.error != nil)) {
                Button("Tamam") { }
            } message: {
                Text(vm.error ?? "Bilinmeyen bir hata oluştu.")
            }
            .sheet(item: $vm.modalPollId) { id in
                NavigationStack {
                    PollView(vm: .init(pollId: id))
                }
            }
            .navigationTitle("Canlı Anketler")
            .onAppear {
                vm.listenToLivePolls()
            }
            .background(
                NavigationLink(
                    destination: LoginView(),
                    isActive: $navigateToLogin,
                    label: { EmptyView() }
                )
            )
        }
    }
    
    // MARK: - Sections
    
    var existingPollSection: some View {
        Section {
            DisclosureGroup("Ankete Katıl") {
                TextField("Anket ID Girin", text: $vm.existingPollId)
                    .textInputAutocapitalization(.none)
                    .autocorrectionDisabled()
                Button("Katıl") {
                    Task { await vm.joinExistingPoll() }
                }
            }
        }
    }
    
    var livePollsSection: some View {
        Section {
            DisclosureGroup("Son Canlı Anketler") {
                ForEach(vm.polls) { poll in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(poll.name)
                                .font(.headline)
                            Spacer()
                            Image(systemName: "chart.bar.xaxis")
                            Text("\(poll.totalCount)")
                            if let updatedAt = poll.updatedAt {
                                Image(systemName: "clock.fill")
                                Text(updatedAt, style: .time)
                            }
                        }
                        PollChartView(options: poll.options)
                            .frame(height: 120)
                    }
                    .padding(.vertical)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        vm.modalPollId = poll.id
                    }
                }
            }
        }
    }
    
    var createPollsSection: some View {
        Section {
            TextField("Anket adı girin", text: $vm.newPollName, axis: .vertical)
                .textInputAutocapitalization(.none)
                .autocorrectionDisabled()
            Button("Oluştur") {
                Task { await vm.createNewPoll() }
            }
            .disabled(vm.isCreateNewPollButtonDisabled)
            
            if vm.isLoading {
                ProgressView()
            }
        } header: {
            Text("Anket Oluştur")
        } footer: {
            Text("Anket adını girin ve oluşturmak için 2-4 seçenek ekleyin.")
        }
    }
    
    var addOptionsSection: some View {
        Section("Seçenekler") {
            TextField("Seçenek ekleyin", text: $vm.newOptionName)
                .textInputAutocapitalization(.none)
                .autocorrectionDisabled()
            Button("+ Seçenek Ekle") {
                vm.addOption()
            }
            .disabled(vm.isAddOptionsButtonDisabled)
            ForEach(vm.newPollOptions) { option in
                Text(option)
            }
            .onDelete { indexSet in
                vm.newPollOptions.remove(atOffsets: indexSet)
            }
        }
    }
    
    var timePickerSection: some View {
        Section {
            TimePickerRow(label: "Başlangıç Saati", date: $startTime, range: Date()...)
            TimePickerRow(label: "Bitiş Saati", date: $endTime, range: startTime...)
        }
    }

    var calendarViewSection: some View {
        Section {
            HStack {
                Text("Tarih Seçimi")
                    .font(.headline)
                Spacer()
                DatePicker("", selection: $selectedDate, in: Date()..., displayedComponents: [.date])
                    .labelsHidden()
            }
        }
    }
    
    // MARK: - Log Out Section
    var logoutSection: some View {
        Section {
            Button("Çıkış Yap") {
                do {
                    try Auth.auth().signOut()
                    DispatchQueue.main.async {
                        navigateToLogin = true
                    }
                } catch {
                    print("Çıkış yaparken bir hata oluştu: \(error.localizedDescription)")
                }
            }
            .foregroundColor(.red)
            .bold()
            .background(
                NavigationLink(
                    destination: LoginView()
                ) {
                    EmptyView()
                }
                .hidden()
            )
        }
    }
}

// MARK: - Helper Views

struct TimePickerRow: View {
    let label: String
    @Binding var date: Date
    let range: PartialRangeFrom<Date>
    
    var body: some View {
        HStack {
            Text(label)
                .font(.headline)
            Spacer()
            DatePicker("", selection: $date, in: range, displayedComponents: [.hourAndMinute])
                .labelsHidden()
                .datePickerStyle(.compact)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HomeView()
    }
}
