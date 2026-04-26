//
//  SceneDelegate.swift
//  Tracker
//
//  Created by Ilia Degtiarev on 12/04/2026.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("Ожидается AppDelegate")
        }
        let dataStores = appDelegate.persistentContainer.createStoreContext()
        let persist = { appDelegate.persistentContainer.saveContext() }
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = Self.makeMainTabBarController(dataStores: dataStores, persistChanges: persist)
        window?.makeKeyAndVisible()
    }

    private static func makeMainTabBarController(dataStores: TrackerDataStores, persistChanges: @escaping () -> Void) -> UITabBarController {
        let trackersVC = TrackerViewController(dataStores: dataStores, persistChanges: persistChanges)
        let trackersNav = UINavigationController(rootViewController: trackersVC)
        trackersNav.navigationBar.prefersLargeTitles = true
        trackersNav.tabBarItem = UITabBarItem(title: "Трекеры", image: UIImage(named: "TrackerIcon"), tag: 0)

        let statisticsVC = StatisticsViewController(dataStores: dataStores)
        let statisticsNav = UINavigationController(rootViewController: statisticsVC)
        statisticsNav.navigationBar.prefersLargeTitles = true
        statisticsNav.tabBarItem = UITabBarItem(title: "Статистика", image: UIImage(named: "StatisticIcon"), tag: 1)

        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [trackersNav, statisticsNav]
        return tabBarController
    }

    func sceneDidDisconnect(_ scene: UIScene) {
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
    }

    func sceneWillResignActive(_ scene: UIScene) {
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.saveContext()
    }
}
