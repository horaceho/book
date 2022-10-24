//
//  ViewController.swift
//  Book
//
//  Created by Horace Ho on 20/10/2022.
//

import UIKit
import PDFKit

class ViewController: UIViewController {

    var hiddenHomeBar: Bool = false
    var hiddenStatusBar: Bool = false

    @IBOutlet weak var pdfView: PDFView?

    @IBOutlet var infoButton: UIView!
    @IBOutlet var menuButton: UIView!
    @IBOutlet var prevButton: UIView!
    @IBOutlet var nextButton: UIView!

    @IBOutlet var configView: UIView! {
        didSet {
            configView.layer.cornerRadius = 8
        }
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return hiddenHomeBar
    }

    override var prefersStatusBarHidden: Bool {
        return hiddenStatusBar
    }

    override func viewWillAppear(_ animated: Bool) {
        print("viewWillAppear")
    }

    override func viewDidAppear(_ animated: Bool) {
        print("viewDidAppear")
    }

    override func viewWillDisappear(_ animated: Bool) {
        print("viewWillDisappear")
    }

    override func viewDidDisappear(_ animated: Bool) {
        print("viewDidDisappear")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        view.addGestureRecognizer(tap)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openUrl(notification:)),
            name: Notification.Name("loadUrl"),
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDocumentChanged(notification:)),
            name: Notification.Name.PDFViewDocumentChanged,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePageChanged(notification:)),
            name: Notification.Name.PDFViewPageChanged,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDisplayBoxChanged(notification:)),
            name: Notification.Name.PDFViewDisplayBoxChanged,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScaleChanged(notification:)),
            name: Notification.Name.PDFViewScaleChanged,
            object: nil
        )

        if let pdf = pdfView {
            let doubleTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleDoubleTap(sender:)))
            doubleTap.numberOfTapsRequired = 2
            pdf.addGestureRecognizer(doubleTap)

            let singleTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleSingleTap(sender:)))
            singleTap.numberOfTapsRequired = 1
            singleTap.require(toFail: doubleTap)
            pdf.addGestureRecognizer(singleTap)

            doubleTap.delaysTouchesBegan = true
            singleTap.delaysTouchesBegan = true
        }
    }

    @objc func handleSingleTap(sender: AnyObject?) {
        pdfView?.goToNextPage(nil)
    }

    @objc func handleDoubleTap(sender: AnyObject?) {
        pdfView?.goToPreviousPage(nil)
    }

    @objc func handleDocumentChanged(notification: Notification) {
        if let pdf = pdfView {
            if let doc = pdf.document {
                if let url = doc.documentURL {
                    debugPrint("handleDocumentChanged: \(url)")
                }
            }
        }
    }

    @objc func handlePageChanged(notification: Notification) {
        if let pdf = pdfView {
            if let page = pdf.currentPage {
                debugPrint("handlePageChanged: \(page)")
            }
        }
    }

    @objc func handleDisplayBoxChanged(notification: Notification) {
        if let pdf = pdfView {
            debugPrint("handleDisplayBoxChanged: \(pdf.displayBox)")
        }
    }

    @objc func handleScaleChanged(notification: Notification) {
        if let pdf = pdfView {
            debugPrint("handleScaleChanged: \(pdf.scaleFactor)")
        }
    }

    @objc func openUrl(notification: Notification) {
        guard
            let url = notification.userInfo?["url"] as? URL
        else { return }
        
        let document = PDFDocument(url: url)

        pdfView?.document = document
        pdfView?.autoScales = true
        pdfView?.displayMode = .singlePage
        pdfView?.pageShadowsEnabled = false

        if let color = UserDefaults.standard.object(forKey: "background") as? String? ?? ".white" {
            for view in pdfView?.subviews ?? [] {
                view.backgroundColor = color == ".clear" ? .clear : .white
            }
        }
    }

    @objc func handleActive() {
        print("handleActive")
        updateSettings()
    }

    @IBAction func tapInsideInfoButton() {
        debugPrintAll()
    }

    @IBAction func tapInsideMenuButton() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }

    @IBAction func tapInsidePrevButton() {
        print("tapInsidePrevButton")
        pdfView?.goToPreviousPage(nil)
    }

    @IBAction func tapInsideNextButton() {
        print("tapInsideNextButton")
        pdfView?.goToNextPage(nil)
    }

    @IBAction func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        print(location)
    }

    @IBAction func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)

        guard let gestureView = gesture.view else {
            return
        }

        gestureView.center = CGPoint(
            x: gestureView.center.x + translation.x,
            y: gestureView.center.y + translation.y
        )

        gesture.setTranslation(.zero, in: view)
    }

    func updateSettings() {
        print("updateSettings")
        if UserDefaults.standard.bool(forKey: "reset") {
            UserDefaults.standard.set(false, forKey: "reset")
            UserDefaults.standard.set(".white", forKey: "background")
            UserDefaults.standard.set(false, forKey: "hiddenHomeBar")
            UserDefaults.standard.set(false, forKey: "hiddenStatusBar")
            UserDefaults.standard.set(false, forKey: "dimMenuButton")
        }

        hiddenHomeBar = UserDefaults.standard.bool(forKey: "hiddenHomeBar")
        self.setNeedsUpdateOfHomeIndicatorAutoHidden()

        hiddenStatusBar = UserDefaults.standard.bool(forKey: "hiddenStatusBar")
        UIView.animate(withDuration: 0.25, animations: {
            self.setNeedsStatusBarAppearanceUpdate()

            let alpha = UserDefaults.standard.bool(forKey: "dimMenuButton") ? 0.2 : 1.0
            self.infoButton.alpha = 0.1
            self.menuButton.alpha = alpha
        })
    }

    func debugPrintAll()
    {
        if let pdf = pdfView {
            debugPrint(pdf)
            if let doc = pdf.document {
                if let url = doc.documentURL {
                    debugPrint("handleDocumentChanged: \(url)")
                }
            }
            debugPrint("isUsingPageViewController: \(pdf.isUsingPageViewController)")
            debugPrint("backgroundColor: \(pdf.backgroundColor)")
            debugPrint("displaysPageBreaks: \(pdf.displaysPageBreaks)")
            debugPrint("displayDirection: \(pdf.displayDirection)")
            debugPrint("displayMode: \(pdf.displayMode)")
            debugPrint("displayBox: \(pdf.displayBox)")
            debugPrint("displaysRTL: \(pdf.displaysRTL)")
            debugPrint("scaleFactor: \(pdf.scaleFactor)")
            debugPrint("autoScales: \(pdf.autoScales)")
            if let page = pdf.page(for: CGPointZero, nearest: true) {
                let rect = pdf.convert(pdf.bounds, to:page)
                debugPrint("viewBounds: \(pdf.bounds) converted: \(rect)")
            }
        }
    }
}
