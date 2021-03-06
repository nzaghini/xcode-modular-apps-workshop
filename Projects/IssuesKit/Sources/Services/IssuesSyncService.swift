import Foundation
import Client
import GitHubKit
import Result
import RxSwift

protocol IssuesSyncServicing {
    func sync(completion: @escaping () -> ())
}

class IssuesSyncService: IssuesSyncServicing {
    
    // MARK: - Private
    
    let client: Client
    let store: IssuesStoring
    
    // MARK: - Init
    
    init(client: Client,
         store: IssuesStoring) {
        self.client = client
        self.store = store
    }
    
    // MARK: - Internal
    
    func sync(completion: @escaping () -> ()) {
        client.execute(resource: Issue.assigned()) { (result) in
            self.response(result: result, issues: [], completion: completion)
        }.resume()
    }
    
    // MARK: - Private
    
    func sync(next: Link, issues: [IssueEntity], completion: @escaping () -> ()) {
        client.execute(resource: resource(link: next, type: Issue.self)) { (result) in
            self.response(result: result, issues: issues, completion: completion)
        }.resume()
    }
    
    func response(result: Result<ClientResponse<([Issue], Link?)>, ClientError>, issues: [IssueEntity], completion: @escaping () -> ()) {
        guard let value = result.value else {
            syncCompleted(issues: issues, completion: completion)
            return
        }
        var mutableIssues = issues
        mutableIssues.append(contentsOf: value.value.0.map(IssueEntity.init))
        if let link = value.value.1 {
            self.sync(next: link, issues: mutableIssues, completion: completion)
        } else {
            self.syncCompleted(issues: mutableIssues, completion: completion)
        }
    }
    
    func syncCompleted(issues: [IssueEntity], completion: @escaping () -> ()) {
        try? store.save(issues)
        completion()
    }
    
}
