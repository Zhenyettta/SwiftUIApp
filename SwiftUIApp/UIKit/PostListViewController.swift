import UIKit

class PostListViewController: UIViewController, PostDetailsViewControllerDelegate, UISearchBarDelegate {
    
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    private var apiPosts: [RedditPost] = []
    private var savedPosts: [RedditPost] = []
    private var filteredSavedPosts: [RedditPost] = []
    private var posts: [RedditPost] {
        return showingSavedPosts ? filteredSavedPosts : apiPosts
    }

    private var after: String?
    private var isLoading = false
    private let pageLimit = 10
    private var showingSavedPosts = false
    private var searchDebounceTimer: Timer?

    @IBOutlet weak var bookmarkButton: UIButton!
    @IBOutlet weak var subredditLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.isHidden = true
        setupTableView()
        fetchPosts()
        bookmarkButton.setImage(UIImage(systemName: "bookmark"), for: .normal)
        bookmarkButton.setTitle("", for: .normal)
        subredditLabel.text = "/r/ios"
        
        searchBar.delegate = self
        searchBar.showsCancelButton = true

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(PostTableViewCell.nib(), forCellReuseIdentifier: PostTableViewCell.identifier)
        tableView.estimatedRowHeight = 300
    }
    
    private func fetchPosts() {
        guard !isLoading else { return }
        guard !showingSavedPosts else { return }
        isLoading = true
        
        APIService.fetchPosts(subreddit: "ios", limit: pageLimit, after: after) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let (newPosts, newAfter)):
                    self?.apiPosts.append(contentsOf: newPosts)
                    self?.after = newAfter
                    self?.tableView.reloadData()
                case .failure(let error):
                    print("Error: \(error)")
                }
            }
        }
    }
    
    @IBAction func bookmarkButtonTapped(_ sender: UIButton) {
        if showingSavedPosts {
            showingSavedPosts = false
            searchBar.resignFirstResponder()
            searchBar.text = ""
            searchBar.isHidden = true
            tableView.reloadData()
            bookmarkButton.setImage(UIImage(systemName: "bookmark"), for: .normal)
        } else {
            searchBar.isHidden = false
            searchBar.text = ""
            loadSavedPosts()
            bookmarkButton.setImage(UIImage(systemName: "bookmark.fill"), for: .normal)
        }
    }

    
    func loadSavedPosts() {
        if let savedPosts = SavedPostsManager().loadSavedPosts() {
            self.savedPosts = savedPosts
            filteredSavedPosts = savedPosts
            showingSavedPosts = true
            tableView.reloadData()
        }
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func didUpdatePost(_ post: RedditPost) {
        if showingSavedPosts {
            loadSavedPosts()
        } else {
            fetchPosts()
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchDebounceTimer?.invalidate()
        searchDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            if self?.showingSavedPosts == true {
                if searchText.isEmpty {
                    self?.filteredSavedPosts = self?.savedPosts ?? []
                } else {
                    self?.filteredSavedPosts = self?.savedPosts.filter { post in
                        post.title.lowercased().contains(searchText.lowercased())
                    } ?? []
                }
                self?.tableView.reloadData()
            }
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        filteredSavedPosts = savedPosts
        tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "go_to_overview",
           let detailsVC = segue.destination as? PostDetailsViewController,
           let post = sender as? RedditPost {
            detailsVC.post = post
            detailsVC.delegate = self
        }
    }
}

extension PostListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: PostTableViewCell.identifier,
            for: indexPath
        ) as! PostTableViewCell
        
        let post = posts[indexPath.section]
        cell.configure(with: post)
        return cell
    }
     
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 15
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.section]
        performSegue(withIdentifier: "go_to_overview", sender: post)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height
        
        if offsetY > contentHeight - height * 2 {
            fetchPosts()
        }
    }
}
