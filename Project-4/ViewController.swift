//
//  ViewController.swift
//  Project-4
//
//  Created by Serhii Prysiazhnyi on 24.10.2024.
//

import UIKit
@preconcurrency import WebKit


class ViewController: UIViewController, WKNavigationDelegate {
    var webView: WKWebView! // Объявление WebView
    var progressView: UIProgressView! // Полоса прогресса для отображения загрузки
    var websites = ["github.com", "apple.com", "hackingwithswift.com"] // Список доступных URL
    
    // Метод для инициализации WebView и назначения его представлением
    override func loadView() {
//        webView = WKWebView()
//        webView.navigationDelegate = self // Назначение делегата для обработки навигации
//        view = webView // Установка WebView в качестве основного представления
        
        let mainView = UIView() // Создаем основной UIView
            webView = WKWebView() // Создаем WKWebView
            webView.navigationDelegate = self // Назначаем делегата
            
            mainView.addSubview(webView) // Добавляем webView в основной UIView
            view = mainView // Устанавливаем основной UIView как основное представление
            
            // Настройка ограничения для webView с учетом безопасной области
            webView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                webView.topAnchor.constraint(equalTo: mainView.safeAreaLayoutGuide.topAnchor),
                webView.bottomAnchor.constraint(equalTo: mainView.safeAreaLayoutGuide.bottomAnchor),
                webView.leadingAnchor.constraint(equalTo: mainView.safeAreaLayoutGuide.leadingAnchor),
                webView.trailingAnchor.constraint(equalTo: mainView.safeAreaLayoutGuide.trailingAnchor)
            ])
    }
    
    // Основной метод загрузки представления
    override func viewDidLoad() {
        super.viewDidLoad()
        
        clearWebKitCache() // Очистка кэша при каждом запуске экрана
        
        // Кнопка "Назад"
        let backButton = UIBarButtonItem(title: "Назад", style: .plain, target: self, action: #selector(goBackTapped))
        // Кнопка "Вперед"
        let forwardButton = UIBarButtonItem(title: "Вперед", style: .plain, target: self, action: #selector(goForwardTapped))
        
        // Настройка кнопки навигации для открытия списка сайтов
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Відкрити", style: .plain, target: self, action: #selector(openTapped)
        )
        
        // Создание и настройка индикатора прогресса
        progressView = UIProgressView(progressViewStyle: .default)
        progressView.sizeToFit()
        let progressButton = UIBarButtonItem(customView: progressView)
        
        // Настройка панели инструментов с кнопками
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let refresh = UIBarButtonItem(barButtonSystemItem: .refresh, target: webView, action: #selector(webView.reload))
        
        toolbarItems = [backButton, forwardButton, progressButton, spacer, refresh] // Добавление кнопок в панель
        navigationController?.isToolbarHidden = false // Отображение панели инструментов
        
        // Загрузка начального URL из списка websites
        let url = URL(string: "https://" + "github.com/Prysiazhnyi?tab=repositories")!  // websites[0])!
        webView.load(URLRequest(url: url))
        webView.allowsBackForwardNavigationGestures = true // Включение навигации вперед и назад
        
        // Добавление наблюдателя для отслеживания прогресса загрузки
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
    }
    
    // Метод для обновления индикатора прогресса при изменении прогресса загрузки
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            progressView.progress = Float(webView.estimatedProgress)
        }
    }
    
    // Метод для обработки нажатия кнопки "Open"
    @objc func openTapped() {
        print("Open button tapped") // Проверка вызова метода
        let ac = UIAlertController(title: "Відкрити сторінку…", message: nil, preferredStyle: .actionSheet)
        
        // Добавляем доступные сайты в UIAlertController
        for website in websites {
            ac.addAction(UIAlertAction(title: website, style: .default, handler: openPage))
        }
        
        // Добавляем кнопку "Cancel" для закрытия
        ac.addAction(UIAlertAction(title: "Відміна", style: .cancel))
        ac.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
        present(ac, animated: true)
    }
    
    // Метод для загрузки выбранной страницы в WebView
    func openPage(action: UIAlertAction) {
        let url = URL(string: "https://" + action.title!)!
        webView.load(URLRequest(url: url))
    }
    
    // Метод делегата для установки заголовка после завершения загрузки страницы
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        title = webView.title
    }
    
    // Метод делегата для ограничения навигации только разрешенными сайтами
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let url = navigationAction.request.url
        
        // Проверка, находится ли хост без поддоменов в списке разрешенных
        if let host = url?.host {
            for website in websites {
                if host.contains(website) {
                    decisionHandler(.allow)
                    print(website)
                    return
                }
            }
        }
        
        if url?.absoluteString == "about:blank" {
            decisionHandler(.allow)
            return
        }
        
        // Сообщение об ошибке при блокировке хоста
        print(url)
        showAlert(for: url?.host)
        decisionHandler(.cancel) // Отменяем навигацию, если хост не разрешен
        
    }
    
    func showAlert(for host: String?) {
        let alert = UIAlertController(
            title: "Заблоковано",
            message: "Доступ до сайту \(host ?? "невідомий") заблоковано.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        // Используем self для показа сообщения
        present(alert, animated: true, completion: nil)
    }
    
    // Метод для очистки кэша WebKit
    func clearWebKitCache() {
        let dataStore = WKWebsiteDataStore.default()
        let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes() // Все типы данных, включая кэш
        
        // Удаляем все данные за все время
        dataStore.removeData(ofTypes: dataTypes, modifiedSince: Date.distantPast) {
            print("WebKit cache cleared.")
        }
    }
    
    // Метод для кнопки "Назад"
    @objc func goBackTapped() {
        if webView.canGoBack {
            webView.goBack()
        }
    }
    
    // Метод для кнопки "Вперед"
    @objc func goForwardTapped() {
        if webView.canGoForward {
            webView.goForward()
        }
    }
    
}

