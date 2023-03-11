extern int read_inotify_event(int fd, Gee.Queue<Linux.InotifyEvent?>? queue);

public class FileSystemNotifier : Object {
    public signal void directory_deleted();
    public signal void children_updated();
    public string directory_path { get; private set; }
    private bool loop_quit_flag;
    private int inotify_fd;
    
    public FileSystemNotifier(string directory_path) {
        this.directory_path = directory_path;
        // inotify初期化
        inotify_fd = Linux.inotify_init();
        if (inotify_fd < 0) {
            print("inotify_init was failed!\n");
            return;
        }
    }
    
    public async void watch() {
        // IOChannelの作成
        IOChannel inotify_channel = new IOChannel.unix_new(inotify_fd);

        // IOChannelのウォッチを開始し、イベント処理を準備する
        inotify_channel.add_watch(IN, (source, condition) => {
            debug("inotify channel watch catched some events!");

            // イベント検知した時の処理
            Gee.ArrayQueue<Linux.InotifyEvent?> queue = new Gee.ArrayQueue<Linux.InotifyEvent?>();
            read_inotify_event(inotify_fd, queue);

            while (queue.size > 0) {
                Linux.InotifyEvent event = queue.poll();
                handle_event();
            }

            Idle.add(watch.callback);
            // ウォッチを続ける場合はtrueを返す
            return true;
        });

        loop_quit_flag = false;
        
        // inotifyイベントループを開始
        while (!loop_quit_flag) {
            // inotifyのウォッチ開始
            int wd = Linux.inotify_add_watch(inotify_fd, directory_path,
                    CREATE | DELETE | DELETE_SELF | MODIFY | MOVE | MOVE_SELF | UNMOUNT | ONESHOT);

            yield; // イベントが起きて処理が終わるまで待つ

            // inotifyのウォッチは一回使ったら終わりなので削除する
            Linux.inotify_rm_watch(inotify_fd, wd);
        }

        // inotifyのファイル記述子を閉じる。
        Posix.close(inotify_fd);
    }
    
    public void quit() {
        loop_quit_flag = true;
    }
    
    private void handle_event() {
        if (!FileUtils.test(directory_path, FileTest.EXISTS)) {
            debug("directory has been deleted!");
            directory_deleted();
        } else {
            debug("directory has been updated!");
            children_updated();
        }
    }
}
