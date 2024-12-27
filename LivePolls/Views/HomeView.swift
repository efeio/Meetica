//
//  HomeView.swift
//  LivePolls
//
//  Created by Efe Koç on 09/07/23.
//

import SwiftUI

struct HomeView: View {
    
    @Bindable var vm = HomeViewModel()
    
    var body: some View {
        List {
            existingPollSection
            livePollsSection
            createPollsSection
            addOptionsSection
        }
        .scrollDismissesKeyboard(.interactively)
        .alert("Error", isPresented: .constant(vm.error != nil)) {
            
        } message: {
            Text(vm.error ?? "an error occured")
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
    }
    
    var existingPollSection: some View {
        Section {
            DisclosureGroup("Ankete Katıl") {
                TextField("Anket ID Girin", text: $vm.existingPollId)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
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
                    VStack {
                        HStack(alignment: .top) {
                            Text(poll.name)
                            Spacer()
                            Image(systemName: "chart.bar.xaxis")
                            Text(String(poll.totalCount))
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
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            
            Button("Oluştur") {
                Task { await vm.createNewPoll() }
            }.disabled(vm.isCreateNewPollButtonDisabled)
            
            if vm.isLoading {
                ProgressView()
            }
        } header: {
            Text("Anket Oluştur")
        } footer: {
            Text("Anket adını girin ve olıuşturmak için 2-4 seçenek ekleyin")
        }
    }
    
    var addOptionsSection: some View {
        Section("Seçenekler") {
            TextField("Seçenek adı girin", text: $vm.newOptionName)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            
            Button("+ Seçenek Ekle") {
                vm.addOption()
            }.disabled(vm.isAddOptionsButtonDisabled)
            
            ForEach(vm.newPollOptions) {
                Text($0)
            }.onDelete { indexSet in
                vm.newPollOptions.remove(atOffsets: indexSet)
            }
        }
    }
}

extension String: Identifiable {
    public var id: Self { self }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
