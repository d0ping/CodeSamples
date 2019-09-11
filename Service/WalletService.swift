import Foundation

@objc protocol WalletServiceObjcType {
    func displayCardsList(host viewController: UIViewController)
}


protocol WalletServiceType {
    func displayCardsList(host viewController: UIViewController)
}

final class WalletService: NSObject, WalletServiceType, WalletServiceObjcType {
    
    private let manager: ABCUIManager
    private let configuration: ABCUIConfiguration
    private let amProvider: AccountManagerProviderType
    private let testingMode: Bool
    
    init(manager: ABCUIManager, configuration: ABCUIConfiguration, amProvider: AccountManagerProviderType, testingMode: Bool) {
        self.manager = manager
        self.configuration = configuration
        self.amProvider = amProvider
        self.testingMode = testingMode
    }
    
    func displayCardsList(host viewController: UIViewController) {
        guard let token = amProvider.am.currentAccount?.token else { return }
        
        let requestsConfiguration = YMWRequestsConfiguration(token: token,
                                                             multipleCardsModeEnabled: true,
                                                             regionId: nil,
                                                             testingMode: testingMode)
        
        manager.displayCardsList(with: configuration,
                                 parentViewController: viewController,
                                 requestsConfiguration: requestsConfiguration)
    }
}
