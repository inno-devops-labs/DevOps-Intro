# Task 1 — Git Object Model Exploration


## Examining Git objects: command outputs

### Blob hash
![](images/blob.png)

### Tree hash
![](images/tree.png)

### Commit hash
![](images/commit.png)


## Explanations on objects
### Blob
A blob stores the contents of a file exactly as-is, with no filename or directory information. If two files have identical contents, Git stores only one blob and reuses it.

### Tree
A tree represents a directory, mapping filenames to blobs (files) and other trees (subdirectories), along with their permissions. It captures the structure of a snapshot.

### Commit
A commit records a snapshot of the project by pointing to a root tree, plus metadata like author, message, and parent commit(s). It forms the history by chaining commits together.


## Storing repository data

### Content-addressable object database
Git stores all repository data as objects in a content-addressable database under .git/objects. Each object is identified by a cryptographic hash, computed from the object’s type, size, and contents. This makes data immutable and ensures integrity: any change produces a new object with a new hash.

### Core object types and snapshot model
Repository state is represented using four object types: blobs (file contents), trees (directory structure), commits (snapshots + metadata), and tags (named references). A commit points to a single root tree, which recursively references blobs and subtrees. This means Git stores snapshots, not diffs—history emerges by linking snapshots via parent commits.

### Deduplication and storage efficiency
Because objects are keyed by content hash, identical data is stored only once. If two files or versions have the same contents, they reference the same blob.

### References and reachability
Branches, tags, and HEAD are lightweight references that store hashes pointing to commits. These refs define which objects are reachable. Git’s garbage collection periodically removes unreachable objects, keeping the repository compact without risking data loss for referenced history.

### Performance implications
This design enables fast operations: checking out a commit is just reading a tree, branching is creating a new reference, and merging is graph analysis over commits. The object graph plus content addressing gives Git both strong consistency guarantees and high performance at scale.


## Example of blob, tree and commit object content
Screenshots were attached in the first subparagraph.


# Task 6: GitHub Community

Starring repositories on GitHub signals appreciation to maintainers, increases project visibility, and helps others discover high-quality open-source work. Following developers makes it easier to track relevant projects, learn best practices from peers, and build professional connections that support effective teamwork and long-term career growth.