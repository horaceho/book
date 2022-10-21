//
//  ViewController.swift
//  Book
//
//  Created by Horace Ho on 20/10/2022.
//

import UIKit
import PDFKit

class ViewController: UIViewController {

    @IBOutlet weak var pdfView: PDFView?

    @IBOutlet var infoText: UITextView!
    @IBOutlet var bookButton: UIView!
    @IBOutlet var prevButton: UIView!
    @IBOutlet var nextButton: UIView!
    @IBOutlet var trashButton: UIView!

    @IBOutlet var configView: UIView! {
        didSet {
            configView.layer.cornerRadius = 8
        }
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

        let doubleTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleDoubleTap(sender:)))
        doubleTap.numberOfTapsRequired = 2
        pdfView?.addGestureRecognizer(doubleTap)

        let singleTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleSingleTap(sender:)))
        singleTap.numberOfTapsRequired = 1
        singleTap.require(toFail: doubleTap)
        pdfView?.addGestureRecognizer(singleTap)

        doubleTap.delaysTouchesBegan = true
        singleTap.delaysTouchesBegan = true
    }

    @objc func handleSingleTap(sender: AnyObject?) {
        pdfView?.goToNextPage(nil)
    }

    @objc func handleDoubleTap(sender: AnyObject?) {
        pdfView?.goToPreviousPage(nil)
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

        if let color = UserDefaults.standard.object(forKey: "background") as? String? ?? ".clear" {
            for view in pdfView?.subviews ?? [] {
                view.backgroundColor = color == ".clear" ? .clear : .white
            }
        }
    }

    @IBAction func tapInsidePrevButton() {
        pdfView?.goToPreviousPage(nil)
    }

    @IBAction func tapInsideNextButton() {
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

}
