# Linux Kernel Container Isolation Primitives

## Top: Isolated Application Container Processes

This section shows two container instances (e.g., in a pod) running a specific app version, demonstrating process and resource isolation. A vertical dashed line separates the two identical `app_node` blocks. A large dashed horizontal line separates the two blocks from the telemetry text below. The horizontal dashed line from 'telemetry pg_tob' in the second box to 'VFS mounts: /usr, /lib' in the fourth block is retained.

| [app_node_01:v1.2] | [app_node_02:v1.2] |
|---|---|
| App Container `PID:1` listen 80:80 | App Container `PID:1` listen 80:80 |
| `fn_process:` | `fn_process:` |
| `if v > 80% { ERROR: REJECT }` | `if v > 80% { ERROR: REJECT }` |
| [Isolated Traffic] [order.created:] | [Isolated Traffic] [order.created: memory] |
| telemetry.ip_tables.. | telemetry.pg_tob.. |

---

## Middle Left: Linux Namespaces

This block illustrates the different kernel namespaces and their interaction, demonstrating per-namespace isolation for various aspects like processes, networking, mounts, etc. The structure of nested and stacked elements is preserved. Two vertical graphical arrows demonstrate bidirectional flow between layers and individual stacked elements within layers.

- [MNT Namespace] [private mounts, rbind]
- [MNT Namespace] [IPC Namespace] [System V IPC, POSIX mqueue] (Stacked with MNT)
- [PID Namespace] [PID:1]
- [NET Namespace] [veth, tun, ip_tables]
- [UTS Namespace] [hostname, domainname]
- [USER Namespace] [root mapping, 0:0 -> 1000:1000] (Stacked with PID Namespace, NET Namespace, UTS Namespace, HOST Namespace)
- [MNT Namespace] [IPC Namespace] [Host Namespace] (Stacked with Host Namespace, but containing a different stack)

---

## Middle Center: Control Groups v2 Resource Limits

This block shows the specific resource controllers and limits set for the containers. The nested and stacked element structure is retained. Vertical stacked elements and a horizontal layout represent different controls. Graphical arrows show relationships. A graphical arrow points from 'If limit is reached: OOM KILL' to the 'Memory Cgroup' stacked element. Graphical arrows connect to and within 'CPU Cgroup' stacked element to 'Host Cgroup'.

| Resource | Control (v2) | Host |
|---|---|---|
| **Memory** | [Memory Cgroup] [memory.max: 2gb swap.max: 0] | |
| **CPU** | [CPU Cgroup] [cpu.max: 50000 100000 quota: 50%] | [Host Cgroup] |
| **I/O** | [BlkIO Cgroup] [blkio.throttle.write_ iops_device: 1000] | [Host Cgroup] |

- **If limit is reached: OOM KILL** points to the stacked structure.

---

## Middle Right: OverlayFS Storage

This section diagrams how the multiple filesystem layers (lower read-only layers and upper read-write container layer) are merged to create the merged view visible to the container process. Stacked elements and text detail individual items. Graphical arrows (e.g., from 'OverlayFS type: overlay, state: MERGED' to Merged View stacked element) define relationships. Database icons are detailed and colored. The text 'OverlayFS type: overlay, state: MERGED' is placed above Merged View and points to it.

- image attestation points from an external text block to stacked elements.
- [External database icons] (detailed and colored)

| Stack Layer | Details | Connection to Merged View | Database |
|---|---|---|---|
| **[Upper Read-Write Container Layer]** | [/etc/app_config.json, /tmp/, HSET config.json {key: v}] | Vertical graphical arrow with depth | |
| | OverlayFS type: overlay, state: MERGED | Pointing graphical arrow | |
| **[Merged View]** | [/bin/app, /var/log] | Unified graphical arrows form a tree structure connecting up, down, and out. | [External database icons] (detailed and colored) |
| **[Lower Read-Only Image Layers]** | [VFS mounts: /usr, /lib] | Vertical graphical arrow with depth | |

---

## Bottom: Host Linux Kernel

This block represents the underlying host kernel subsystems that manage the isolation primitives. All original elements (Process Scheduler, Networking Stack (TCP/IP), I/O Subsystem (Block, Virtual File System), Memory Management, Syscall Interface), their specific technical terms (VFS mounts, ip_tables, tune.ssl), detailed colored database icons, and all text labels are perfectly retained. 'SAST Reports [telemetry, violations]adapted from <IMAGE_1>' (Flex/Code 10pt) is integrated into the colored box. Graphical arrows (colored) form a seamless chain demonstrating data flow from Process Scheduler to Syscall Interface. Additional colored graphical arrows (blue-to-teal gradient) sweep across the entire chain from left-to-right to visualize the trend not explicitly stated in words.

- Colorful professional fonts (Flex/Code 10pt) for all titles and labels.
- Sub-headings 'like in <IMAGE 1>' or ASCII arrows are replaced by colored graphical equivalents.
- Text like 'telemetry pg_tob..', 'if v > 80%', 'if retry > 3', 'status: OK' use Google Sans Code, while main labels like 'Process Scheduler', 'Memory Cgroup' use Google Sans Flex.
- The entire image is enclosed in a colored professional continuous gray border line, like a technical chart.
- The continuous line border frames the entire image professionally.
- No actual font types names are written in the image. All technical and descriptive content are sharp and clear. All original layout details and content meaning are preserved, with text formatting as requested. The continuous outer gray line weight frames the whole image professionally. All data is perfectly retained in the original layout. No artistic display of font names. Colored professional vector icons and arrows are clean and detailed. The colorful graphical arrows are clean and directional. The complex colored graphical arrows with depth demonstrate flow direction and connection. All text in parentheses (e.g., (Static Analysis), (telemetry, violations), VFS mounts:, ip_tables, [events], [XSS: <script>alert(1)</script>, SQLi: ' OR 1=1]) uses Google Sans Code. Main descriptive text like Process Scheduler, Source Repository, Staging Deployment & DAST, use Google Sans Flex. All status indicators like status: OK, READ_WRITE use Code. Text in square brackets [telemetry.haproxy:] uses Code. All CVE numbers and descriptions are present. Version numbers and port details are correct. All code blocks use Google Sans Code. All external icons are detailed and colored. The entire image is colorful, professional, and within a single continuous frame line. Text sizes are exact. Graphical arrows and connections demonstrate seamless flow. There are no ASCII arrows. All text and logic is perfectly preserved and accurate. Colored professional text rendering creates visual clarity.
