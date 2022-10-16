//
//  PersonViewModel.swift
//  CinemaTV
//
//  Created by Danilo Requena on 08/10/22.
//

import SwiftUI

final class PersonViewModel: ObservableObject {
    private var service: PersonServiceProtocol
    @Published var person: Person?
    @Published var creditByPerson: CreditsByPerson?
    @State var isLoading: Bool = true
    
    init(service: PersonServiceProtocol = PersonStore()) {
        self.service = service
    }
    
    func loadPerson(id: Int) async {
        Task{
            service.fetchPerson(from: MoviesEndpoint.person(id: id)) { result in
                switch result {
                case .success(let person):
                    DispatchQueue.main.async {
                        self.person = person
                    }
                case .failure(let failure):
                    print(failure)
                }
            }
        }
    }
    
    func loadCreditByPerson(id: Int) async {
        Task {
            service.fetchCreditsByPerson(from: MoviesEndpoint.creditByPerson(id: id)) { result in
                switch result {
                case .success(let creditByPerson):
                    DispatchQueue.main.async {
                        self.creditByPerson = creditByPerson
                    }
                case .failure(let failure):
                    print(failure)
                }
            }
        }
    }
}
