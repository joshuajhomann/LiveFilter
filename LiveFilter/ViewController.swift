//
//  ViewController.swift
//  LiveFilter
//
//  Created by Joshua Homann on 6/17/17.
//  Copyright © 2017 josh. All rights reserved.
//

import UIKit
import AVFoundation
import GLKit

class ViewController: UIViewController {
    private lazy var captureSession: AVCaptureSession = {
        let session = AVCaptureSession()
        session.sessionPreset = .high
        return session
    }()

    private lazy var ciImageView: CIImageView = { [unowned self] in
        let ciImageView = CIImageView(frame: self.view.bounds)
        ciImageView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(ciImageView)
        ciImageView.topAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        ciImageView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        ciImageView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        ciImageView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        ciImageView.isHidden = true
        return ciImageView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back) else {
            return
        }
        do {
            captureSession.beginConfiguration()
            let videoInput = try AVCaptureDeviceInput(device: backCameraDevice)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            }
            captureSession.commitConfiguration()
        } catch let error {
            print(error)
        }
        captureSession.beginConfiguration()
        let output = AVCaptureVideoDataOutput()
        if captureSession.canAddOutput(output) {
            let queue = DispatchQueue(label: "queue.capture")
            output.setSampleBufferDelegate(self, queue: queue)
            captureSession.addOutput(output)
        }
        captureSession.commitConfiguration()
        captureSession.startRunning()
        ciImageView.isHidden = false
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer =  CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer).applyingFilter("CIColorInvert", withInputParameters: nil)
        DispatchQueue.main.async {
            self.ciImageView.image = ciImage
        }
    }
}

class CIImageView: GLKView, GLKViewDelegate {
    var ciContext: CIContext!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        self.context = EAGLContext(api: .openGLES2)!
        EAGLContext.setCurrent(self.context)
        self.ciContext = CIContext(eaglContext: self.context)
        delegate = self
        enableSetNeedsDisplay = true
        isOpaque  = false
    }

    var image: CIImage? {
        didSet {
            self.setNeedsDisplay()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
    }

    public func glkView(_ view: GLKView, drawIn rect: CGRect) {
        glClearColor(0, 0, 0, 0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))

        guard let image = self.image else {
            return
        }
        let scale = UIScreen.main.scale
        let scaledRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width * scale, height: rect.height * scale)
        self.ciContext.draw(image, in: scaledRect, from: image.extent)
    }
}

