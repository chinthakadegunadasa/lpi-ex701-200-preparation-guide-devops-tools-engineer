# Chapter 21: Prometheus Monitoring & Metrics Engineering

Effective monitoring is the backbone of modern DevOps and Site Reliability Engineering (SRE). In cloud-native, distributed systems, traditional up/down checking is insufficient. We need deep observability into internal application state and infrastructure performance. Prometheus has emerged as the CNCF standard for metrics-based monitoring due to its dimensional data model, powerful query language, and scalable architecture.

This chapter provides a comprehensive, enterprise-focused, hands-on guide to mastering Prometheus, aligned with the LPI 701-200 DevOps Tools Engineer objectives.

## 21.1 Prometheus Pull-Based Metrics Architecture & TSDB Storage

Understanding the core architecture of Prometheus is crucial for designing a robust monitoring solution. Unlike many traditional systems that use an agent on hosts to "push" metrics to a central server, Prometheus primarily uses a "pull" mechanism.

### The Pull-Based Architecture

Prometheus scrapes metrics from monitored targets over HTTP.

1. **Retrieval (Scraper):** The Prometheus server is configured with a list of jobs and targets. At defined intervals (the `scrape_interval`), it sends HTTP requests to the `/metrics` endpoint of these targets.
2. **Targets:** A target can be an application, a host (via Node Exporter), or an intermediary like Pushgateway. The target must expose metrics in a text-based format that Prometheus understands.
3. **Service Discovery:** In dynamic enterprise environments (like Kubernetes or AWS), hardcoding targets is impossible. Prometheus integrates with service discovery mechanisms (DNS, Consul, EC2, Kubernetes API) to automatically discover and scrape new instances as they come online.
4. **Storage (TSDB):** Scraped data is compressed and stored locally on disk in a custom Time Series Database (TSDB).

**Why Pull?**

* **Decoupling:** Targets don't need to know where the central monitoring server is.
* **Centralized Control:** The monitoring server dictates *how often* and *what* to scrape. If a target is down, Prometheus knows immediately because the pull fails. If a push-based agent dies, the server just sees a lack of data, which could mean the network is down, the server is slow, or the agent is dead.
* **Simplicity:** No complex agents required for standard metrics; simply expose an HTTP endpoint.

### TSDB Storage Fundamentals

Prometheus stores data as time series: streams of timestamped values belonging to the same metric and the same set of labeled dimensions.

**The Data Model:**
`metric_name{label_name=label_value, ...} value timestamp`

Example:
`http_requests_total{method="post", handler="/api/login", status="200"} 1452 1696412345`

* **Metric Name:** Specifies the general feature being measured (e.g., `http_requests_total`).
* **Labels (Dimensions):** Key-value pairs that qualify the metric name. This allows for powerful filtering and aggregation (e.g., give me total requests *where* method is "post").
* **Sample:** The actual value (a float64) and the timestamp (millisecond resolution).

**Storage on Disk:**
The TSDB organizes data into blocks. Each block holds data for a specific time range (default 2 hours). A block consists of:

* **Chunks:** The actual compressed sample data.
* **Index:** Indexes metric names and labels to chunks for fast querying.
* **WAL (Write-Ahead Log):** Incoming data is first written to the WAL to prevent data loss in case of a crash before it's persisted to a block.

**Enterprise Consideration: Long-Term Storage:**
By default, Prometheus is designed for short-term, high-resolution operational data (retention defaults to 15 days). For long-term storage, trending, and capacity planning, enterprises often integrate Prometheus with remote storage backends like Thanos, Cortex, or VictoriaMetrics using the `remote_write` API.

## 21.2 Core Metric Types: Counters, Gauges, Histograms, and Summaries

Prometheus defines four core metric types in its client libraries. Choosing the right type for the specific behavior you are measuring is critical for accurate monitoring and querying.

### 1. Counter

A counter is a cumulative metric that represents a single monotonically increasing counter whose value can only increase or be reset to zero on restart. You do **not** use a counter to expose a value that can decrease.

* **Use Cases:** Number of requests served, errors encountered, tasks completed.
* **PromQL:** Almost always used with the `rate()` or `irate()` function to calculate requests per second, error rate, etc.

*Enterprise Example:* Monitoring the API Gateway error rate. If `api_errors_total` spikes, an alert triggers.

### 2. Gauge

A gauge is a metric that represents a single numerical value that can arbitrarily go up and down.

* **Use Cases:** Memory usage, CPU temperature, number of concurrent requests, disk usage.
* **PromQL:** Used directly to see the current state or with functions like `delta()` or `predict_linear()`.

*Enterprise Example:* Monitoring available memory on critical database servers. Alerting if free memory drops below 10%.

### 3. Histogram

A histogram samples observations (usually things like request durations or response sizes) and counts them in configurable buckets. It also provides a sum of all observed values.

* **Structure:**
* `<basename>_bucket{le="<upper_inclusive_bound>"}`: Counter of observations with value less than or equal to the bound.
* `<basename>_sum`: Total sum of all observed values.
* `<basename>_count`: Total number of observations (identical to `le="+Inf"` bucket).


* **Use Cases:** Request latency (SLA/SLI monitoring), response sizes.
* **PromQL:** Used with the `histogram_quantile()` function to calculate quantiles (e.g., 95th percentile latency).

*Enterprise Example:* Ensuring API response time SLA. Calculate the p99 latency using `histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))`. If p99 > 500ms, alert.

### 4. Summary

Similar to a histogram, a summary samples observations (e.g., request durations). While it also provides a total count and sum of observations, it calculates configurable quantiles over a sliding time window on the *client side*, rather than the server side like Histograms.

* **Structure:**
* `{quantile="<quantile_value>"}`: The calculated quantile value.
* `<basename>_sum`
* `<basename>_count`


* **Use Cases:** Quick insight into latencies when bucket configuration for histograms is unknown or when server-side aggregation across instances is not required.
* **Pros:** Easy to set up, precise quantiles on a per-instance basis.
* **Cons:** **Cannot** be aggregated across multiple instances. If you have 10 instances of a microservice, you cannot calculate the p95 latency for the entire service using Summaries.

*Enterprise Consensus:* For almost all enterprise use cases requiring aggregation (which is most), **Histograms are preferred over Summaries**.

## 21.3 PromQL (Prometheus Query Language) Masterclass: Aggregations, Rates, and Functions

PromQL is the powerful functional query language designed specifically for the Prometheus dimensional data model. It allows you to select, aggregate, and transform time series data in real-time. Masterclass understanding is required for complex alerting and meaningful dashboards.

### Basic Selection and Filtering

* Select all time series with metric name `http_requests_total`:
`http_requests_total`
* Select series where `method` is "GET" and `handler` is "/api/v1/users":
`http_requests_total{method="GET", handler="/api/v1/users"}`
* Select series where `status` *does not* start with 2 (regex mismatch):
`http_requests_total{status!~"2.."}`

### Range Vectors

Range vectors select a range of data over time for each series. They are denoted by `[time]`. These **cannot** be graphed directly; they must be passed to a function that results in an instant vector.

* Select the last 5 minutes of data for `node_cpu_seconds_total`:
`node_cpu_seconds_total[5m]`

### Core Functions and Operators

#### `rate()`

Calculates the per-second average rate of increase of the time series in the range vector. It should *only* be used with Counters. It handles counter resets automatically.

* Calculate the average HTTP requests per second over the last 5 minutes:
`rate(http_requests_total[5m])`

#### `irate()`

Calculates the instant rate of increase, looking only at the last two samples in the range vector. Useful for zoomable, high-resolution graphing but should **not** be used for alerting, as it's too volatile.

#### `sum()`

Aggregates the values of all selected time series into a single value.

* Calculate total memory usage across all nodes:
`sum(node_memory_Active_bytes)`

#### Aggregation `by` and `without`

Allows aggregating while preserving specific dimensions.

* Calculate average HTTP request rate per handler:
`sum(rate(http_requests_total[5m])) by (handler)`

#### Arithmetic Operators

Standard operators (`+`, `-`, `*`, `/`, `%`, `^`) work between two instant vectors or an instant vector and a scalar.

* Calculate CPU usage percentage (1 - idle percentage):
`(1 - sum(rate(node_cpu_seconds_total{mode="idle"}[5m])) by (instance) / sum(rate(node_cpu_seconds_total[5m])) by (instance)) * 100`

### Advanced Aggregations and Top K

#### `histogram_quantile()`

Calculates a specific quantile from a Histogram metric. This is essential for latency SLIs.

* Calculate the 95th percentile request duration for the 'frontend' job:
`histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket{job="frontend"}[5m])) by (le))`

#### `topk()` and `bottomk()`

Returns the K time series with the highest or lowest values.

* Show the top 5 CPU consuming instances:
`topk(5, rate(node_cpu_seconds_total{mode="user"}[5m]))`

## 21.4 Node Exporters, Application Instrumentation, and Pushgateway

Getting data *into* Prometheus requires either instrumenting the application code directly or using an exporter.

### Node Exporter

The Node Exporter is an official Prometheus exporter for machine metrics. It is designed to be run as a daemon on the host operating system (Linux, WMI Exporter for Windows).

* **Metrics Exposed:** CPU, memory, disk I/O, network usage, filesystem fullness, load average.
* **Enterprise Use:** Standard component on all infrastructure VMs or bare metal servers. In Kubernetes, it runs as a DaemonSet on every node.

### Application Instrumentation

This is the process of adding Prometheus client library calls directly into your application code to expose internal metrics. Libraries exist for virtually all major languages (Go, Java, Python, Ruby, Node.js, .NET).

* **Approach:**
1. Define metrics (Counters, Gauges, etc.) globally in the code.
2. Increment Counters when events happen (e.g., `requests_total.inc()`).
3. Set Gauges to reflect state (e.g., `queue_size.set(q.length)`).
4. Observe Histograms (e.g., `timer.observe(duration)`).
5. Expose the `/metrics` endpoint via an HTTP handler.



**Example (Python):**

```python
from prometheus_client import start_http_server, Counter, Summary
import time
import random

# Define metrics
REQUESTS = Counter('hello_worlds_total', 'Total Hello Worlds served.')
LATENCY = Summary('hello_world_latency_seconds', 'Time spent processing request')

# Decorate function with metric.
@LATENCY.time()
def process_request(t):
    """A dummy function that takes some time."""
    time.sleep(t)
    REQUESTS.inc()

if __name__ == '__main__':
    # Start up the server to expose the metrics.
    start_http_server(8000)
    # Generate some requests.
    while True:
        process_request(random.random())

```

### Pushgateway

While Prometheus is pull-based, some jobs cannot be scraped. These are typically short-lived batch jobs or ephemeral processes that finish before Prometheus can pull their metrics.

The Pushgateway acts as an intermediary. Short-lived jobs push their metrics to the Pushgateway via HTTP. Prometheus then scrapes the Pushgateway at its usual interval.

* **Enterprise Warning:** **The Pushgateway is often misused.** It should *only* be used for ephemeral batch jobs.
* **Drawbacks:**
* Single point of failure for batch monitoring.
* No automatic "up" metric from the source job; Prometheus sees Pushgateway is up, but doesn't know if the source job crashed *unless* that job specifically pushes complex health state.
* Data persists in Pushgateway until manually deleted; if a batch job stops running, the last metrics pushed will be scraped forever.



## 21.5 Hands-On Lab: Instrumenting Custom Microservice Metrics and Writing Advanced PromQL Queries

### Lab Overview

In this lab, you will act as a DevOps Engineer tasked with improving the observability of a critical internal microservice, the `OrderService`. Currently, only infrastructure metrics are available. You will instrument the Python-based `OrderService` with custom metrics using the official Prometheus client library. Then, you will run the service, have Prometheus scrape it, and write advanced PromQL queries to gain insights.

### Prerequisites

* A Linux environment (VM or container).
* Docker and Docker Compose installed.
* Basic knowledge of Python.

### Step 1: Set Up the Environment

1. Create a directory for the lab:
`mkdir prom-lab && cd prom-lab`
2. Create a Docker Compose file (`docker-compose.yml`) to run Prometheus:

```yaml
version: '3.8'
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
    networks:
      - lab-net

networks:
  lab-net:
    driver: bridge

```

3. Create a basic Prometheus configuration file (`prometheus.yml`) to scrape itself:

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

```

4. Start Prometheus:
`docker-compose up -d`
5. Verify Prometheus is running by accessing `http://localhost:9090` in your browser.

### Step 2: Write and Instrument the Microservice

1. Install the Python client library:
`pip install prometheus_client flask`
2. Create the `OrderService` (`app.py`):

```python
import time
import random
from flask import Flask, jsonify
from prometheus_client import start_http_server, Counter, Gauge, Histogram, make_wsgi_app
from werkzeug.middleware.dispatcher import DispatcherMiddleware

app = Flask(__name__)

# --- Metrics Definition ---
# 1. Counter for total orders processed
ORDERS_TOTAL = Counter('order_service_orders_total', 'Total number of orders processed.', ['status'])

# 2. Gauge for active orders in flight
ACTIVE_ORDERS = Gauge('order_service_active_orders', 'Number of orders currently being processed.')

# 3. Histogram for order processing latency (buckets in seconds)
PROCESSING_LATENCY = Histogram('order_service_processing_latency_seconds',
                                'Time taken to process an order.',
                                buckets=[0.1, 0.5, 1.0, 2.5, 5.0, 10.0])

# Simulate order processing logic
def do_process_order():
    ACTIVE_ORDERS.inc() # Increment Gauge
    start_time = time.time()

    # Simulate variable latency
    latency = random.expovariate(1.0) # Average of 1 second
    time.sleep(latency)

    # Simulate success/failure
    status = "success" if random.random() > 0.1 else "failure" # 10% failure rate
    ORDERS_TOTAL.labels(status=status).inc() # Increment Counter with labels

    PROCESSING_LATENCY.observe(time.time() - start_time) # Observe Histogram
    ACTIVE_ORDERS.dec() # Decrement Gauge
    return status

@app.route('/order', methods=['POST'])
def place_order():
    status = do_process_order()
    return jsonify({"order_status": status})

if __name__ == '__main__':
    # Add prometheus wsgi middleware to route /metrics requests
    app.wsgi_app = DispatcherMiddleware(app.wsgi_app, {
        '/metrics': make_wsgi_app()
    })
    # Run the Flask app on port 5000
    app.run(host='0.0.0.0', port=5000)

```

### Step 3: Integrate Microservice and Prometheus

1. Run the OrderService in a separate terminal:
`python app.py`
2. Update `prometheus.yml` to scrape the `OrderService`. *Important:* Since Prometheus is in a container, it cannot use `localhost:5000`. We need to use the host's IP address. Find your host's IP (e.g., using `ip addr show` on the bridge interface). Let's assume it's `172.17.0.1`.

```yaml
global:
  scrape_interval: 5s # Faster scraping for the lab

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'order_service'
    static_configs:
      - targets: ['172.17.0.1:5000'] # Replace with your host IP

```

3. Restart the Prometheus container:
`docker-compose restart prometheus`
4. Verify the target is up: Go to `http://localhost:9090/targets`. The `order_service` job should show as `UP`.

### Step 4: Generate Traffic and Verify Metrics

1. Generate some order traffic using `curl` in a loop (run this in a separate terminal):
`while true; do curl -X POST http://localhost:5000/order; sleep 1; done`
2. Access the raw metrics: Open `http://localhost:5000/metrics`. You should see lines like:
```
# HELP order_service_orders_total Total number of orders processed.
# TYPE order_service_orders_total counter
order_service_orders_total{status="failure"} 2.0
order_service_orders_total{status="success"} 23.0
...
# HELP order_service_processing_latency_seconds Time taken to process an order.
# TYPE order_service_processing_latency_seconds histogram
order_service_processing_latency_seconds_bucket{le="0.1"} 1.0
order_service_processing_latency_seconds_bucket{le="0.5"} 12.0
...

```



### Step 5: Advanced PromQL Masterclass

Now, use the Prometheus Expression Browser (`http://localhost:9090`) to execute the following queries. These represent real-world SRE scenarios.

**Scenario A: Infrastructure Health**

* **Goal:** Calculate current available memory on all nodes (we don't have Node Exporter here, so let's use a Prometheus internal metric as a proxy).
* **Query:** Total samples currently stored in the TSDB.
`prometheus_tsdb_head_series`

**Scenario B: Red-Line Alerting (Enterprise Use Case)**

* **Goal:** Alert if the order error rate exceeds 5% over the last 2 minutes. This is a critical business metric.
* **Query Analysis:**
1. Get rate of failures: `rate(order_service_orders_total{status="failure"}[2m])`
2. Get rate of total orders: `sum(rate(order_service_orders_total[2m]))`
3. Calculate percentage: `(rate(...) / sum(rate(...))) * 100`


* **Final PromQL:**
`(sum(rate(order_service_orders_total{status="failure"}[2m])) / sum(rate(order_service_orders_total[2m]))) * 100`

**Scenario C: Latency SLI/SLO (Enterprise Use Case)**

* **Goal:** Calculate the 99th percentile order processing latency over the last 5 minutes. This measures the worst-case user experience.
* **Query Analysis:**
1. Use `histogram_quantile(0.99, ...)`
2. Aggregate rates of buckets: `sum(rate(order_service_processing_latency_seconds_bucket[5m])) by (le)`


* **Final PromQL:**
`histogram_quantile(0.99, sum(rate(order_service_processing_latency_seconds_bucket[5m])) by (le))`

**Scenario D: Resource Planning and Anomaly Detection**

* **Goal:** Use a gauge to find the top 3 instances by number of active orders in flight.
* **Query:**
`topk(3, order_service_active_orders)`

### Lab Conclusion and Key Takeaways

By completing this lab, you have:

1. Handled the complete lifecycle of application observability: from defining requirements to implementation, integration, and analysis.
2. Gained invaluable hands-on experience instrumenting code with standard Prometheus metric types (Counter, Gauge, Histogram).
3. Mastered the configuration of Prometheus for scraping dynamic application targets.
4. Constructed complex, enterprise-grade PromQL queries for critical alerting (error rates) and SLI monitoring (quantiles), bridging the gap between raw data and actionable SRE insights.
