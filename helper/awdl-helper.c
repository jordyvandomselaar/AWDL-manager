// Applies the saved AWDL mode immediately and keeps awdl0 down in off mode.
// Runs as root. Wakes on interface changes (routing socket) and on mode
// changes (kqueue on the state directory), so there is no polling gap.
#include <fcntl.h>
#include <grp.h>
#include <net/if.h>
#include <os/log.h>
#include <stdbool.h>
#include <string.h>
#include <sys/event.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <sys/sockio.h>
#include <sys/stat.h>
#include <unistd.h>

#define IFACE "awdl0"
#define STATE_DIR "/Library/Application Support/AWDL Manager"
#define MODE_FILE STATE_DIR "/mode"

static os_log_t logger;
static int ctl;

static bool mode_is_on(void) {
    char buf[8] = {0};
    int fd = open(MODE_FILE, O_RDONLY);
    if (fd < 0) return false;
    ssize_t n = read(fd, buf, sizeof buf - 1);
    close(fd);
    return n >= 2 && strncmp(buf, "on", 2) == 0;
}

static void set_up(bool up) {
    struct ifreq ifr = {0};
    strlcpy(ifr.ifr_name, IFACE, sizeof ifr.ifr_name);
    if (ioctl(ctl, SIOCGIFFLAGS, &ifr) < 0) return;
    if (((ifr.ifr_flags & IFF_UP) != 0) == up) return;
    ifr.ifr_flags = up ? (ifr.ifr_flags | IFF_UP) : (ifr.ifr_flags & ~IFF_UP);
    if (ioctl(ctl, SIOCSIFFLAGS, &ifr) < 0)
        os_log_error(logger, "could not set %{public}s %{public}s", IFACE, up ? "up" : "down");
    else
        os_log(logger, "set %{public}s %{public}s", IFACE, up ? "up" : "down");
}

static void prepare_state(void) {
    struct group *admin = getgrnam("admin");
    mkdir(STATE_DIR, 0775);
    chown(STATE_DIR, 0, admin ? admin->gr_gid : 0);
    chmod(STATE_DIR, 0775);
    int fd = open(MODE_FILE, O_WRONLY | O_CREAT | O_EXCL, 0664);
    if (fd < 0) return;
    write(fd, "off\n", 4);
    fchown(fd, 0, admin ? admin->gr_gid : 0);
    close(fd);
}

int main(void) {
    logger = os_log_create("app.jordy.awdl-manager", "helper");
    prepare_state();

    ctl = socket(AF_INET, SOCK_DGRAM, 0);
    int routes = socket(PF_ROUTE, SOCK_RAW, AF_UNSPEC);
    int dir = open(STATE_DIR, O_EVTONLY);
    int kq = kqueue();
    if (ctl < 0 || routes < 0 || dir < 0 || kq < 0) {
        os_log_error(logger, "setup failed");
        return 1;
    }

    struct kevent watch[2];
    EV_SET(&watch[0], routes, EVFILT_READ, EV_ADD, 0, 0, NULL);
    EV_SET(&watch[1], dir, EVFILT_VNODE, EV_ADD | EV_CLEAR, NOTE_WRITE, 0, NULL);
    kevent(kq, watch, 2, NULL, 0, NULL);

    bool on = mode_is_on();
    set_up(on);

    char msg[2048];
    for (;;) {
        struct kevent ev;
        if (kevent(kq, NULL, 0, &ev, 1, NULL) < 1) continue;
        if ((int)ev.ident == dir) {
            on = mode_is_on();
            set_up(on);
        } else {
            read(routes, msg, sizeof msg);
            if (!on) set_up(false);
        }
    }
}
