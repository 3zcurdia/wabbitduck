//
//  ReportView.swift
//  Wabbit
//
//  Created by Luis Ezcurdia on 11/3/17.
//  Copyright © 2017 Luis Ezcurdia. All rights reserved.
//

import UIKit

class ReportView: UIView {
    let reportCellId = "reportCell"
    let actionCellId = "actionCell"
    let infoView: DeviceInfoView = {
        let dv = DeviceInfoView()
        dv.translatesAutoresizingMaskIntoConstraints = false
        return dv
    }()
    let langView: LanguagesView = {
        let lv = LanguagesView()
        lv.translatesAutoresizingMaskIntoConstraints = false
        return lv
    }()

    let reportsCollection: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .black
        cv.refreshControl = UIRefreshControl()
        cv.refreshControl?.backgroundColor = .platinum
        cv.refreshControl?.addTarget(self, action: #selector(refreshBenchmarks), for: .valueChanged)
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()

    var reportGroups: [ReportGroup]? {
        didSet {
            DispatchQueue.main.async { self.reportsCollection.reloadData() }
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        reportsCollection.register(ReportViewCell.self, forCellWithReuseIdentifier: self.reportCellId)
        reportsCollection.register(SwipeActionViewCell.self, forCellWithReuseIdentifier: self.actionCellId)
        reportsCollection.delegate = self
        reportsCollection.dataSource = self
        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        addSubview(infoView)
        NSLayoutConstraint.activate([
            infoView.topAnchor.constraint(equalTo: topAnchor),
            infoView.leadingAnchor.constraint(equalTo: leadingAnchor),
            infoView.trailingAnchor.constraint(equalTo: trailingAnchor),
            infoView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.14)
            ])
        addSubview(langView)
        NSLayoutConstraint.activate([
            langView.topAnchor.constraint(equalTo: infoView.bottomAnchor),
            langView.leadingAnchor.constraint(equalTo: leadingAnchor),
            langView.trailingAnchor.constraint(equalTo: trailingAnchor),
            langView.heightAnchor.constraint(equalToConstant: 44)
            ])
        addSubview(reportsCollection)
        NSLayoutConstraint.activate([
            reportsCollection.topAnchor.constraint(equalTo: langView.bottomAnchor),
            reportsCollection.leadingAnchor.constraint(equalTo: leadingAnchor),
            reportsCollection.trailingAnchor.constraint(equalTo: trailingAnchor),
            reportsCollection.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
    }

    @objc func refreshBenchmarks() {
        reportsCollection.refreshControl?.beginRefreshing()
        let startTime = Date()
        BenchmarkService.shared.run(onUpdate: { reports in
            self.reportGroups = reports
        }, completion: {
            self.infoView.elapsedTime = Date().timeIntervalSince(startTime)
            self.reportsCollection.refreshControl?.endRefreshing()
        })
    }
}

extension ReportView: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return reportGroups?.count ?? 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let unwrapedGroups = reportGroups {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reportCellId,
                                                                for: indexPath) as? ReportViewCell else { return UICollectionViewCell() }
            cell.reportGroup = unwrapedGroups[indexPath.row]
            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: actionCellId,
                                                                for: indexPath) as? SwipeActionViewCell else { return UICollectionViewCell() }
            cell.text = "Swipe down to run benchmarks!"
            return cell
        }
    }
}

extension ReportView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 125.0
        if reportGroups == nil { height = reportsCollection.frame.height }
        return CGSize(width: reportsCollection.frame.width, height: height)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func invalidateCollectionViewLayout() {
        self.reportsCollection.collectionViewLayout.invalidateLayout()
    }
}
