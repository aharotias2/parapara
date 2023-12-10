
#include <gee-0.8/gee.h>
#include <sys/inotify.h>
#include <stdio.h>

typedef struct inotify_event InotifyEvent;

int read_inotify_event(int fd, GeeQueue* queue) {
    char buffer[30000];
    int buffer_i = 0;

    // ファイル記述子から読み込んでバッファにデータを写す
    int r = read(fd, buffer, 30000);
    InotifyEvent* pevent;

    while (buffer_i < r) {
        // バッファからinotify_event構造体を読み出す。
        InotifyEvent* pevent = (InotifyEvent*) &buffer[buffer_i];

        // inotify_event構造体のサイズは16 + lenフィールドの値
        int event_size = sizeof(InotifyEvent) + pevent->len;

        // キューに入れるため、メモリを確保する
        InotifyEvent* event = malloc(event_size);

        // inotify_event構造体をコピーする
        memmove(event, pevent, event_size);

        // コピーしたinotify_event構造体へのポインタをキューに入れる
        gee_queue_offer(queue, event);

        // イベントを最後まで読み込む
        buffer_i += event_size;
    }
    return 0;
}
