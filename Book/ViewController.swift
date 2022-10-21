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
    }

    @objc func openUrl(notification: Notification) {
        guard
            let url = notification.userInfo?["url"] as? URL
        else { return }
        
        let document = PDFDocument(url: url)

        pdfView?.document = document
        pdfView?.autoScales = true
        pdfView?.displayMode = .singlePage
    }

    @IBAction func tapInsideBookButton() {
        openBook()
    }

    @IBAction func tapInsidePrevButton() {
        pdfView?.goToPreviousPage(nil)
        pdfView?.backgroundColor = .clear
    }

    @IBAction func tapInsideNextButton() {
        pdfView?.goToNextPage(nil)
        pdfView?.backgroundColor = .clear
    }

    @IBAction func tapInsideTrashButton() {
      // do something
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

    func openBook()
    {
        if let pdfUrl = Bundle.main.url(forResource: "WatchOS9", withExtension: "pdf") {
            let document = PDFDocument(url: pdfUrl)

            pdfView?.document = document
            pdfView?.autoScales = true
            pdfView?.displayMode = .singlePage
        }
    }

}
