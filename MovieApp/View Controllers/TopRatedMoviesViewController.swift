//
//  TopRatedMoviesVC.swift
//  MovieApp
//
//  Created by Esraa Mohamed Ragab on 5/15/19.
//

import UIKit

class TopRatedMoviesViewController: BaseViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var topRatedMoviesCollectionView: UICollectionView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var reloadButton: UIButton!
    
    // MARK: - Properties
    
    private var pageNum = 1
    private var totalPages = 1
    private var isWating = false
    private var results : [Results] = []
    private var list = true
    
    // MARK: - ViewController Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCollectionView()
        MoviesSQLiteDataBase.MovieDatabase.createMoviesDataBase()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        pageNum = 1
        totalPages = 1
        results = []
        topRatedMoviesCollectionView.reloadData()
        callApiGetMovies()
    }
    
    // MARK: - IBActions
    
    @IBAction private func reloadData(_ sender: Any) {
        callApiGetMovies()
    }
    
    @IBAction private func gridDisplay(_ sender: Any) {
        list = false
        topRatedMoviesCollectionView.reloadData()
    }
    
    @IBAction private func listDisplay(_ sender: Any) {
        list = true
        topRatedMoviesCollectionView.reloadData()
    }
    
    // MARK: - API Call
    
    private func callApiGetMovies(){
        self.reloadButton.isHidden = true
        if pageNum > totalPages {
            return
        } else {
            loadingIndicator.startAnimating()
        }
        if NetworkManager.sharedInstance.isConnected() {
            NetworkManager.sharedInstance.serverRequests(url: "https://api.themoviedb.org/3/movie/top_rated?api_key=\(Constants.api.api_key.rawValue)&language=en-US&page=\(pageNum)", success: { (res) in
                let moviesDic = Movies.init(fromDictionary: res)
                self.results.append(contentsOf: moviesDic.results)
                self.insertMoviesInsideSQLDatabase(movies: moviesDic.results)
                self.totalPages = moviesDic.totalPages
                self.isWating = false
                self.topRatedMoviesCollectionView.reloadData()
                self.loadingIndicator.stopAnimating()
                self.reloadButton.isHidden = true
            }) { (error) in
                self.getMoviesFromDataBase(message: error["status_message"] as? String ?? "Error")
            }
        } else {
            getMoviesFromDataBase(message: "Please Connect to the Internet..")
        }
    }
    
    // MARK: - Prepare for Segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "movieDetails" {
            let dest = segue.destination as! MovieDetailsViewController
            dest.movie = results[sender as! Int]
        }
    }
}

// MARK: - Collection View Delegate FlowLayout

extension TopRatedMoviesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if list {
            return CGSize(width: collectionView.frame.width - 40, height: 110)
        } else {
            return CGSize(width: (collectionView.frame.width - 60)/2, height: 230)
        }
    }
}

// MARK: - Collection View DataSource

extension TopRatedMoviesViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return results.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = list ? collectionView.dequeueReusableCell(withReuseIdentifier: "FullRawCell", for: indexPath) as! FullRawCell : collectionView.dequeueReusableCell(withReuseIdentifier: "SubRawCell", for: indexPath) as! SubRawCell
        let item = results[indexPath.row]
        cell.layer.shadowOffset = CGSize(width: 0, height: 1)
        cell.layer.shadowRadius = 8
        cell.layer.shadowOpacity = 0.6
        cell.layer.shadowColor = (UIColor().black).cgColor
        cell.layer.masksToBounds = false
        cell.layer.shadowPath = UIBezierPath(roundedRect:cell.bounds, cornerRadius:cell.contentView.layer.cornerRadius).cgPath
        
        (cell as? FullRawCell)?.configureCell(title: item.title, average: "\(item.voteAverage!)", date: item.releaseDate, posterImage: item.posterPath)
        (cell as? SubRawCell)?.configureCell(title: item.title, average: "\(item.voteAverage!)", date: item.releaseDate, posterImage: item.posterPath)
        return cell
    }
}

// MARK: - Collection View Delegate

extension TopRatedMoviesViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: "movieDetails", sender: indexPath.row)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.row == results.count - 2 && !isWating {
            isWating = true
            pageNum += 1
            self.getMoreMovies()
        }
    }
}

// MARK: - Database Connect

extension TopRatedMoviesViewController {
    private func insertMoviesInsideSQLDatabase(movies: [Results]) {
        if pageNum == 1 {
            MoviesSQLiteDataBase.MovieDatabase.deleteAllMovies()
        }
        for movie in movies {
            MoviesSQLiteDataBase.MovieDatabase.addMovieToMovies(movie: movie)
        }
    }
    
    private func getMoviesFromDataBase(message: String) {
        if MoviesSQLiteDataBase.MovieDatabase.selectAllMovies() != [] {
            self.results = MoviesSQLiteDataBase.MovieDatabase.selectAllMovies()
            self.reloadButton.isHidden = true
            self.isWating = false
            self.topRatedMoviesCollectionView.reloadData()
            self.loadingIndicator.stopAnimating()
        } else {
            reloadButton.isHidden = self.pageNum == 1 ? false : true
            self.pageNum == 1 ? Alert(title: "Error!", message: message, VC: self): nil
            loadingIndicator.stopAnimating()
        }
    }
}

// MARK: - Private Functions

extension TopRatedMoviesViewController {
    private func configureCollectionView() {
        topRatedMoviesCollectionView.register(UINib(nibName: "FullRawCell", bundle: nil), forCellWithReuseIdentifier: "FullRawCell")
        topRatedMoviesCollectionView.register(UINib(nibName: "SubRawCell", bundle: nil), forCellWithReuseIdentifier: "SubRawCell")
    }
    
    private func getMoreMovies() {
        callApiGetMovies()
    }
}
