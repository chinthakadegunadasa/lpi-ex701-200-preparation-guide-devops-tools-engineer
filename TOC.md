```html
<table style="width: 100%; table-layout: fixed; border-collapse: collapse;">
  <colgroup>
    <col style="width: 88%;">
    <col style="width: 12%;">
  </colgroup>
  <thead>
    <tr style="border-bottom: 1px solid #000;">
      <th style="text-align: left; padding: 4px 0;">Section / Chapter</th>
      <th style="text-align: right; padding: 4px 0;">Page</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td style="padding: 4px 0; overflow: hidden; text-overflow: ellipsis;">Introduction & Certification Matrix</td>
      <td style="text-align: right; padding: 4px 0;">i</td>
    </tr>
    <tr>
      <td style="padding: 4px 0; overflow: hidden; text-overflow: ellipsis;">Suggested Next Steps & Matrix Usage</td>
      <td style="text-align: right; padding: 4px 0;">ii</td>
    </tr>
    <tr>
      <td style="padding: 4px 0; overflow: hidden; text-overflow: ellipsis;"><b>Chapter 1: Cloud-Native Architecture Patterns</b></td>
      <td style="text-align: right; padding: 4px 0;"><b>1</b></td>
    </tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">1.1 Monolithic vs. Microservices vs. Serverless Paradigms</td><td style="text-align: right; padding: 3px 0;">1</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">1.2 API-First Architectures: RESTful APIs, gRPC, and GraphQL</td><td style="text-align: right; padding: 3px 0;">2</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">1.3 Event-Driven Architecture & Message Queuing</td><td style="text-align: right; padding: 3px 0;">4</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">1.4 Enterprise Scalability, Fault Tolerance, and High Availability</td><td style="text-align: right; padding: 3px 0;">5</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">1.5 Hands-On Lab: Decoupling a Monolithic Application into Event-Driven Microservices</td><td style="text-align: right; padding: 3px 0;">6</td></tr>

    <tr>
      <td style="padding: 4px 0; overflow: hidden; text-overflow: ellipsis;"><b>Chapter 2: Enterprise Cloud-Native Architecture & Microservices Implementation</b></td>
      <td style="text-align: right; padding: 4px 0;"><b>12</b></td>
    </tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">2.1 Architectural Paradigms & System Deconstruction</td><td style="text-align: right; padding: 3px 0;">12</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">2.2 Enterprise Inter-Service Communication</td><td style="text-align: right; padding: 3px 0;">13</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">2.3 Event-Driven Messaging Infrastructure</td><td style="text-align: right; padding: 3px 0;">14</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">2.4 Resiliency Architecture Patterns</td><td style="text-align: right; padding: 3px 0;">14</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">2.5 Enterprise Implementation Lab: Decoupled Order System</td><td style="text-align: right; padding: 3px 0;">15</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">2.6 Shift-Left Security Principles in CI/CD Pipelines</td><td style="text-align: right; padding: 3px 0;">18</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">2.7 Static Application Security Testing (SAST) and Dynamic Scanning (DAST)</td><td style="text-align: right; padding: 3px 0;">19</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">2.8 Software Supply Chain Security & Dependency Vulnerability Scanning</td><td style="text-align: right; padding: 3px 0;">21</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">2.9 Enterprise Secrets Management Standards</td><td style="text-align: right; padding: 3px 0;">22</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">2.10 Hands-On Lab: Building Complete SAST/DAST Vulnerability Scanning Pipeline</td><td style="text-align: right; padding: 3px 0;">23</td></tr>

    <tr>
      <td style="padding: 4px 0; overflow: hidden; text-overflow: ellipsis;"><b>Chapter 3: Enterprise Application Integration & API Gateways</b></td>
      <td style="text-align: right; padding: 4px 0;"><b>26</b></td>
    </tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">3.1 Enterprise Service Bus vs. Modern API Gateways</td><td style="text-align: right; padding: 3px 0;">26</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">3.2 Kong and APISIX API Gateway Architecture</td><td style="text-align: right; padding: 3px 0;">27</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">3.3 Rate Limiting, Throttling, and Authentication Plugins</td><td style="text-align: right; padding: 3px 0;">27</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">3.4 API Versioning and Lifecycle Management</td><td style="text-align: right; padding: 3px 0;">28</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">3.5 Hands-On Lab: Deploying Kong API Gateway with Custom Rate Limiting</td><td style="text-align: right; padding: 3px 0;">28</td></tr>

    <tr>
      <td style="padding: 4px 0; overflow: hidden; text-overflow: ellipsis;"><b>Chapter 4: Enterprise Middleware & Application Services</b></td>
      <td style="text-align: right; padding: 4px 0;"><b>28</b></td>
    </tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">4.1 Reverse Proxies and Web Application Firewalls (NGINX, HAProxy)</td><td style="text-align: right; padding: 3px 0;">28</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">4.2 Enterprise Messaging Brokers (RabbitMQ, Apache Kafka)</td><td style="text-align: right; padding: 3px 0;">29</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">4.3 In-Memory Caching Strategies (Redis, Memcached)</td><td style="text-align: right; padding: 3px 0;">30</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">4.4 Database Connection Pooling and Read/Write Splitting</td><td style="text-align: right; padding: 3px 0;">30</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">4.5 Hands-On Lab: Provisioning HAProxy, Redis, and RabbitMQ Application Stack</td><td style="text-align: right; padding: 3px 0;">31</td></tr>

    <tr>
      <td style="padding: 4px 0; overflow: hidden; text-overflow: ellipsis;"><b>Chapter 5: Docker Containerization Architecture & Core Operations</b></td>
      <td style="text-align: right; padding: 4px 0;"><b>36</b></td>
    </tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">5.1 Container Internals: Namespaces, cgroups, and OverlayFS</td><td style="text-align: right; padding: 3px 0;">36</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">5.2 Docker Engine Architecture: Docker Daemon, containerd, and runc</td><td style="text-align: right; padding: 3px 0;">38</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">5.3 Writing Enterprise Dockerfiles & Multi-Stage Builds</td><td style="text-align: right; padding: 3px 0;">39</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">5.4 Image Optimization, Layer Caching, and Security Hardening</td><td style="text-align: right; padding: 3px 0;">42</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">5.5 Hands-On Lab: Constructing Minimalistic, Hardened Multi-Stage Container Images</td><td style="text-align: right; padding: 3px 0;">43</td></tr>

    <tr>
      <td style="padding: 4px 0; overflow: hidden; text-overflow: ellipsis;"><b>Chapter 6: Advanced Container Storage & Overlay Networking</b></td>
      <td style="text-align: right; padding: 4px 0;"><b>47</b></td>
    </tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">6.1 Docker Storage Drivers (Overlay2, btrfs, zfs)</td><td style="text-align: right; padding: 3px 0;">47</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">6.2 Persistent Volumes, Bind Mounts, and Tmpfs Mounts</td><td style="text-align: right; padding: 3px 0;">49</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">6.3 Docker Networking Drivers: Bridge, Host, Macvlan, and Overlay</td><td style="text-align: right; padding: 3px 0;">50</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">6.4 Enterprise Multi-Host Networking Configuration</td><td style="text-align: right; padding: 3px 0;">51</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">6.5 Hands-On Lab: Configuring Cross-Node Container Overlay Networks with Custom Subnets</td><td style="text-align: right; padding: 3px 0;">52</td></tr>

    <tr>
      <td style="padding: 4px 0; overflow: hidden; text-overflow: ellipsis;"><b>Chapter 7: Service Discovery & Dynamic Routing</b></td>
      <td style="text-align: right; padding: 4px 0;"><b>56</b></td>
    </tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">7.1 Principles of Service Discovery in Distributed Systems</td><td style="text-align: right; padding: 3px 0;">56</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">7.2 HashiCorp Consul Cluster Deployment and Service Registration</td><td style="text-align: right; padding: 3px 0;">60</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">7.3 Dynamic Reverse Proxying with Traefik and NGINX</td><td style="text-align: right; padding: 3px 0;">64</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">7.4 Health Checking and Automated Traffic Rerouting</td><td style="text-align: right; padding: 3px 0;">68</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">7.5 Hands-On Lab: Integrating HashiCorp Consul with Traefik for Automatic Dynamic Routing</td><td style="text-align: right; padding: 3px 0;">71</td></tr>

    <tr>
      <td style="padding: 4px 0; overflow: hidden; text-overflow: ellipsis;"><b>Chapter 8: Enterprise Kubernetes Architecture & Operations</b></td>
      <td style="text-align: right; padding: 4px 0;"><b>80</b></td>
    </tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">8.1 Kubernetes Control Plane Components</td><td style="text-align: right; padding: 3px 0;">80</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">8.2 Worker Node Architecture</td><td style="text-align: right; padding: 3px 0;">83</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">8.3 kubectl CLI Configuration and API Interactivity</td><td style="text-align: right; padding: 3px 0;">85</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">8.4 Production Cluster Bootstrapping Standards (kubeadm)</td><td style="text-align: right; padding: 3px 0;">86</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">8.5 Hands-On Lab: Bootstrapping a Multi-Node Kubernetes Control Plane via Kubeadm</td><td style="text-align: right; padding: 3px 0;">89</td></tr>

    <tr>
      <td style="padding: 4px 0; overflow: hidden; text-overflow: ellipsis;"><b>Chapter 9: Kubernetes Workload Management</b></td>
      <td style="text-align: right; padding: 4px 0;"><b>96</b></td>
    </tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">9.1 Pod Lifecycle, Phase Transitions, and Health Probes</td><td style="text-align: right; padding: 3px 0;">96</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">9.2 Deployments, Rollouts, and Rollback Mechanics</td><td style="text-align: right; padding: 3px 0;">100</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">9.3 StatefulSets: Ordered Provisioning and Persistent Identity</td><td style="text-align: right; padding: 3px 0;">101</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">9.4 DaemonSets, Jobs, and CronJobs</td><td style="text-align: right; padding: 3px 0;">104</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">9.5 Kubernetes Services and Ingress Controllers</td><td style="text-align: right; padding: 3px 0;">106</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">9.6 Hands-On Lab: Deploying a High-Availability Stateful Workload with Ingress Routing</td><td style="text-align: right; padding: 3px 0;">109</td></tr>

    <tr>
      <td style="padding: 4px 0; overflow: hidden; text-overflow: ellipsis;"><b>Chapter 10: Kubernetes Storage, ConfigMaps, & Secrets</b></td>
      <td style="text-align: right; padding: 4px 0;"><b>113</b></td>
    </tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">10.1 PersistentVolumes (PV), PersistentVolumeClaims (PVC), and Dynamic Provisioning</td><td style="text-align: right; padding: 3px 0;">113</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">10.2 Container Storage Interface (CSI) Drivers</td><td style="text-align: right; padding: 3px 0;">115</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">10.3 Decoupling Configuration using ConfigMaps</td><td style="text-align: right; padding: 3px 0;">116</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">10.4 Managing Sensitive Data with Kubernetes Secrets and External Secret Store Integration</td><td style="text-align: right; padding: 3px 0;">118</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">10.5 Hands-On Lab: Provisioning Ceph CSI Persistent Volumes with External HashiCorp Vault Secrets</td><td style="text-align: right; padding: 3px 0;">119</td></tr>

    <tr>
      <td style="padding: 4px 0; overflow: hidden; text-overflow: ellipsis;"><b>Chapter 11: Kubernetes Security & RBAC</b></td>
      <td style="text-align: right; padding: 4px 0;"><b>125</b></td>
    </tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">11.1 Kubernetes Authentication & Authorization Engine</td><td style="text-align: right; padding: 3px 0;">125</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">11.2 Role-Based Access Control (RBAC): ServiceAccounts, Roles, ClusterRoles, and Bindings</td><td style="text-align: right; padding: 3px 0;">128</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">11.3 Restricting Network Traffic using Kubernetes NetworkPolicies</td><td style="text-align: right; padding: 3px 0;">130</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">11.4 Pod Security Standards (PSS) and Admission Controllers</td><td style="text-align: right; padding: 3px 0;">132</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">11.5 Hands-On Lab: Implementing Zero-Trust Network Policies and Granular RBAC</td><td style="text-align: right; padding: 3px 0;">133</td></tr>

    <tr>
      <td style="padding: 4px 0; overflow: hidden; text-overflow: ellipsis;"><b>Chapter 12: IaC Architecture & State Management</b></td>
      <td style="text-align: right; padding: 4px 0;"><b>138</b></td>
    </tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">12.1 Declarative vs. Imperative Infrastructure Paradigm</td><td style="text-align: right; padding: 3px 0;">138</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">12.2 Terraform / OpenTofu Architecture and Provider Ecosystem</td><td style="text-align: right; padding: 3px 0;">140</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">12.3 Managing State Files: Remote Backends, State Locking, and Security</td><td style="text-align: right; padding: 3px 0;">142</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">12.4 State Inspection, Import, and Refactoring Strategies</td><td style="text-align: right; padding: 3px 0;">144</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">12.5 Hands-On Lab: Provisioning Remote State Storage with S3 Backend and Lock Table</td><td style="text-align: right; padding: 3px 0;">146</td></tr>

    <tr>
      <td style="padding: 4px 0; overflow: hidden; text-overflow: ellipsis;"><b>Chapter 13: Declarative Infrastructure Provisioning</b></td>
      <td style="text-align: right; padding: 4px 0;"><b>154</b></td>
    </tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">13.1 HCL (HashiCorp Configuration Language) Syntax and Data Types</td><td style="text-align: right; padding: 3px 0;">154</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">13.2 Dynamic Infrastructure with Variables, Outputs, and Locals</td><td style="text-align: right; padding: 3px 0;">157</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">13.3 Enterprise Module Architecture and Reusability</td><td style="text-align: right; padding: 3px 0;">159</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">13.4 Resource Lifecycle Management and Workspace Management</td><td style="text-align: right; padding: 3px 0;">161</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">13.5 Hands-On Lab: Building Modular Terraform Code for Automated Cloud Node Provisioning</td><td style="text-align: right; padding: 3px 0;">163</td></tr>

    <tr>
      <td style="padding: 4px 0; overflow: hidden; text-overflow: ellipsis;"><b>Chapter 14: Ansible Architecture & Core Playbooks</b></td>
      <td style="text-align: right; padding: 4px 0;"><b>167</b></td>
    </tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">14.1 Agentless Configuration Management Engine & SSH Control</td><td style="text-align: right; padding: 3px 0;">167</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">14.2 Inventory Files (Static vs. Dynamic Inventory Engines)</td><td style="text-align: right; padding: 3px 0;">170</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">14.3 Writing Idempotent Ansible Tasks and Playbooks</td><td style="text-align: right; padding: 3px 0;">172</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">14.4 Variables, Facts, Handlers, and Conditionals</td><td style="text-align: right; padding: 3px 0;">173</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">14.5 Hands-On Lab: Writing an Idempotent Multi-Tier Application Server Playbook</td><td style="text-align: right; padding: 3px 0;">175</td></tr>

    <tr>
      <td style="padding: 4px 0; overflow: hidden; text-overflow: ellipsis;"><b>Chapter 15: Advanced Ansible Patterns, Roles, & Automation</b></td>
      <td style="text-align: right; padding: 4px 0;"><b>181</b></td>
    </tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">15.1 Structuring Enterprise Codebases with Ansible Roles</td><td style="text-align: right; padding: 3px 0;">181</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">15.2 Managing Secrets with Ansible Vault</td><td style="text-align: right; padding: 3px 0;">185</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">15.3 Dynamic Inventories for Cloud and Virtualization Enclaves</td><td style="text-align: right; padding: 3px 0;">187</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">15.4 Asynchronous Execution, Poll Options, and Error Handling</td><td style="text-align: right; padding: 3px 0;">190</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">15.5 Hands-On Lab: Implementing Encrypted Ansible Roles with Automated Dynamic Inventories</td><td style="text-align: right; padding: 3px 0;">194</td></tr>

    <tr>
      <td style="padding: 4px 0; overflow: hidden; text-overflow: ellipsis;"><b>Chapter 16: Automated Immutable Image Pipelines</b></td>
      <td style="text-align: right; padding: 4px 0;"><b>201</b></td>
    </tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">16.1 Packer and Cloud-init in Immutable Infrastructure</td><td style="text-align: right; padding: 3px 0;">201</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">16.2 HashiCorp Packer Architecture: Builders, Provisioners, and Post-Processors</td><td style="text-align: right; padding: 3px 0;">203</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">16.3 Automating OS Provisioning via Cloud-init and Kickstart</td><td style="text-align: right; padding: 3px 0;">206</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">16.4 Integrating Packer into CI/CD Automated Pipelines</td><td style="text-align: right; padding: 3px 0;">208</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">16.5 Hands-On Lab: Building Automated Hardened Debian 13 Golden Machine Images</td><td style="text-align: right; padding: 3px 0;">209</td></tr>

    <tr>
      <td style="padding: 4px 0; overflow: hidden; text-overflow: ellipsis;"><b>Chapter 17: GitOps & Continuous Delivery Workflows</b></td>
      <td style="text-align: right; padding: 4px 0;"><b>216</b></td>
    </tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">17.1 GitOps Principles: Declarative Infrastructure and Single Source of Truth</td><td style="text-align: right; padding: 3px 0;">216</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">17.2 ArgoCD Architecture, Application Controllers, and Sync Policies</td><td style="text-align: right; padding: 3px 0;">218</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">17.3 Flux CD Toolkit and Multi-Tenancy Management</td><td style="text-align: right; padding: 3px 0;">221</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">17.4 Automated Rollbacks and Progressive Delivery (Argo Rollouts)</td><td style="text-align: right; padding: 3px 0;">223</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">17.5 Hands-On Lab: Implementing GitOps Continuous Delivery with ArgoCD and GitHub Actions</td><td style="text-align: right; padding: 3px 0;">225</td></tr>

    <tr>
      <td style="padding: 4px 0; overflow: hidden; text-overflow: ellipsis;"><b>Chapter 18: Observability, Metrics, & Monitoring Architecture</b></td>
      <td style="text-align: right; padding: 4px 0;"><b>232</b></td>
    </tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">18.1 Metrics, Logs, and Traces: The Three Pillars of Observability</td><td style="text-align: right; padding: 3px 0;">232</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">18.2 Prometheus Architecture: Scraping, TSDB Storage, and PromQL</td><td style="text-align: right; padding: 3px 0;">234</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">18.3 Enterprise Visualization with Grafana Dashboards and Alerting Rules</td><td style="text-align: right; padding: 3px 0;">238</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">18.4 Distributed Tracing with OpenTelemetry and Jaeger</td><td style="text-align: right; padding: 3px 0;">241</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">18.5 Hands-On Lab: Deploying a Full Observability Stack with Prometheus, Grafana, and OpenTelemetry</td><td style="text-align: right; padding: 3px 0;">244</td></tr>

    <tr>
      <td style="padding: 4px 0; overflow: hidden; text-overflow: ellipsis;"><b>Chapter 19: Centralized Logging & Log Analytics</b></td>
      <td style="text-align: right; padding: 4px 0;"><b>252</b></td>
    </tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">19.1 Enterprise Log Aggregation Paradigms</td><td style="text-align: right; padding: 3px 0;">252</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">19.2 Fluentbit and Fluentd Architecture for Lightweight Log Collection</td><td style="text-align: right; padding: 3px 0;">254</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">19.3 Grafana Loki: Cost-Effective Log Indexing and LogQL</td><td style="text-align: right; padding: 3px 0;">257</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">19.4 Elasticsearch, Logstash, and Kibana (ELK) Stack Operations</td><td style="text-align: right; padding: 3px 0;">260</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">19.5 Hands-On Lab: Configuring Fluentbit and Loki for Kubernetes Cluster Log Ingestion</td><td style="text-align: right; padding: 3px 0;">264</td></tr>

    <tr>
      <td style="padding: 4px 0; overflow: hidden; text-overflow: ellipsis;"><b>Chapter 20: Enterprise Service Mesh Architecture</b></td>
      <td style="text-align: right; padding: 4px 0;"><b>270</b></td>
    </tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">20.1 Service Mesh Fundamentals: Control Plane vs. Data Plane</td><td style="text-align: right; padding: 3px 0;">270</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">20.2 Istio Architecture: Envoy Proxy Sidecars, Pilot, and Citadel</td><td style="text-align: right; padding: 3px 0;">273</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">20.3 Mutual TLS (mTLS), Traffic Management, and Circuit Breaking</td><td style="text-align: right; padding: 3px 0;">277</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">20.4 Lightweight Alternatives: Linkerd and Consul Service Mesh</td><td style="text-align: right; padding: 3px 0;">280</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">20.5 Hands-On Lab: Enforcing Zero-Trust mTLS and Traffic Splitting with Istio</td><td style="text-align: right; padding: 3px 0;">283</td></tr>

    <tr>
      <td style="padding: 4px 0; overflow: hidden; text-overflow: ellipsis;"><b>Chapter 21: High-Performance Load Balancing & Global Traffic Management</b></td>
      <td style="text-align: right; padding: 4px 0;"><b>291</b></td>
    </tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">21.1 Anycast Routing and Border Gateway Protocol (BGP) Basics</td><td style="text-align: right; padding: 3px 0;">291</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">21.2 CoreDNS and Advanced DNS Management for Cloud-Native Environments</td><td style="text-align: right; padding: 3px 0;">294</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">21.3 Layer 4 and Layer 7 Load Balancing with MetalLB and Envoy Gateway</td><td style="text-align: right; padding: 3px 0;">297</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">21.4 Global Traffic Distribution and Failover Strategies</td><td style="text-align: right; padding: 3px 0;">300</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">21.5 Hands-On Lab: Configuring BGP Routing and Load Balancing with MetalLB in Kubernetes</td><td style="text-align: right; padding: 3px 0;">303</td></tr>

    <tr>
      <td style="padding: 4px 0; overflow: hidden; text-overflow: ellipsis;"><b>Chapter 22: Enterprise Database High Availability & Clustering</b></td>
      <td style="text-align: right; padding: 4px 0;"><b>310</b></td>
    </tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">22.1 Distributed Database Architecture and Consensus Protocols (Raft, Paxos)</td><td style="text-align: right; padding: 3px 0;">310</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">22.2 PostgreSQL High Availability with Patroni, Etcd, and HAProxy</td><td style="text-align: right; padding: 3px 0;">313</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">22.3 MySQL InnoDB Cluster and Replication Topologies</td><td style="text-align: right; padding: 3px 0;">318</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">22.4 Distributed SQL Databases: YugabyteDB and CockroachDB</td><td style="text-align: right; padding: 3px 0;">322</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">22.5 Hands-On Lab: Deploying an Enterprise-Grade Fault-Tolerant PostgreSQL Cluster with Patroni</td><td style="text-align: right; padding: 3px 0;">326</td></tr>

    <tr>
      <td style="padding: 4px 0; overflow: hidden; text-overflow: ellipsis;"><b>Chapter 23: Disaster Recovery, Backup, and Cluster Migration</b></td>
      <td style="text-align: right; padding: 4px 0;"><b>334</b></td>
    </tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">23.1 Disaster Recovery Planning and RPO/RTO Metrics</td><td style="text-align: right; padding: 3px 0;">334</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">23.2 Kubernetes Backup and Migration with Velero and Object Storage</td><td style="text-align: right; padding: 3px 0;">337</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">23.3 Etcd Snapshot Backup, Verification, and Disaster Recovery Procedures</td><td style="text-align: right; padding: 3px 0;">341</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">23.4 Cross-Cluster State Synchronization and Data Replication</td><td style="text-align: right; padding: 3px 0;">344</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">23.5 Hands-On Lab: Performing Automated Disaster Recovery and Restoration with Velero</td><td style="text-align: right; padding: 3px 0;">347</td></tr>

    <tr>
      <td style="padding: 4px 0; overflow: hidden; text-overflow: ellipsis;"><b>Chapter 24: Enterprise Security Information, Event Management, & Compliance</b></td>
      <td style="text-align: right; padding: 4px 0;"><b>354</b></td>
    </tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">24.1 Runtime Security Monitoring with Falco</td><td style="text-align: right; padding: 3px 0;">354</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">24.2 Vulnerability Management and Compliance Scanning with OpenSCAP and Trivy</td><td style="text-align: right; padding: 3px 0;">358</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">24.3 Integrating Security Information and Event Management (SIEM) Systems</td><td style="text-align: right; padding: 3px 0;">362</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">24.4 Incident Response Playbooks for Cloud-Native Environments</td><td style="text-align: right; padding: 3px 0;">365</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">24.5 Hands-On Lab: Detecting Container Breakouts and Security Anomalies with Falco</td><td style="text-align: right; padding: 3px 0;">368</td></tr>

    <tr>
      <td style="padding: 4px 0; overflow: hidden; text-overflow: ellipsis;"><b>Chapter 25: Edge Computing and Lightweight Kubernetes</b></td>
      <td style="text-align: right; padding: 4px 0;"><b>375</b></td>
    </tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">25.1 Edge Architecture Challenges and Resource Constraints</td><td style="text-align: right; padding: 3px 0;">375</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">25.2 Lightweight Kubernetes Distributions: K3s and MicroK8s</td><td style="text-align: right; padding: 3px 0;">378</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">25.3 Managing Distributed Edge Fleets with Rancher or KubeEdge</td><td style="text-align: right; padding: 3px 0;">382</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">25.4 Offline Synchronization and Local Data Caching</td><td style="text-align: right; padding: 3px 0;">385</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">25.5 Hands-On Lab: Deploying a Multi-Node Edge Cluster Using K3s</td><td style="text-align: right; padding: 3px 0;">388</td></tr>

    <tr>
      <td style="padding: 4px 0; overflow: hidden; text-overflow: ellipsis;"><b>Chapter 26: Multi-Cloud and Hybrid Cloud Federation</b></td>
      <td style="text-align: right; padding: 4px 0;"><b>395</b></td>
    </tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">26.1 Multi-Cloud Strategy and Architectural Patterns</td><td style="text-align: right; padding: 3px 0;">395</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">26.2 Cluster Federation and Global Service Discovery with Karmada</td><td style="text-align: right; padding: 3px 0;">398</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">26.3 Cross-Cluster Networking with Submariner</td><td style="text-align: right; padding: 3px 0;">402</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">26.4 Workload Portability and Data Synchronization Across Clouds</td><td style="text-align: right; padding: 3px 0;">405</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">26.5 Hands-On Lab: Establishing Cross-Cluster Secure Connectivity with Submariner</td><td style="text-align: right; padding: 3px 0;">408</td></tr>

    <tr>
      <td style="padding: 4px 0; overflow: hidden; text-overflow: ellipsis;"><b>Chapter 27: Site Reliability Engineering (SRE) & Production Operations</b></td>
      <td style="text-align: right; padding: 4px 0;"><b>415</b></td>
    </tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">27.1 SRE Principles: Error Budgets, SLIs, and SLOs</td><td style="text-align: right; padding: 3px 0;">415</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">27.2 Incident Management, Post-Mortems, and Blameless Culture</td><td style="text-align: right; padding: 3px 0;">418</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">27.3 Capacity Planning, Load Testing, and Chaos Engineering (Chaos Mesh)</td><td style="text-align: right; padding: 3px 0;">421</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">27.4 Automation and Toil Reduction Strategies</td><td style="text-align: right; padding: 3px 0;">425</td></tr>
    <tr><td style="padding: 3px 0 3px 16px; overflow: hidden; text-overflow: ellipsis;">27.5 Hands-On Lab: Injecting Chaos Engineering Experiments into Kubernetes Deployments</td><td style="text-align: right; padding: 3px 0;">428</td></tr>

    <tr>
      <td style="padding: 4px 0; overflow: hidden; text-overflow: ellipsis;">Appendix A: Linux Kernel Tuning & Performance Optimization for Distributed Systems</td>
      <td style="text-align: right; padding: 4px 0;">436</td>
    </tr>
    <tr>
      <td style="padding: 4px 0; overflow: hidden; text-overflow: ellipsis;">Appendix B: Enterprise Command-Line Reference & Automation Cheat Sheet</td>
      <td style="text-align: right; padding: 4px 0;">445</td>
    </tr>
    <tr>
      <td style="padding: 4px 0; overflow: hidden; text-overflow: ellipsis;">Appendix C: Troubleshooting Methodologies and Root Cause Analysis Frameworks</td>
      <td style="text-align: right; padding: 4px 0;">455</td>
    </tr>
    <tr>
      <td style="padding: 4px 0; overflow: hidden; text-overflow: ellipsis;">Appendix D: Hardening Standards & Compliance Checklists (CIS, NIST, SOC 2)</td>
      <td style="text-align: right; padding: 4px 0;">465</td>
    </tr>
    <tr>
      <td style="padding: 4px 0; overflow: hidden; text-overflow: ellipsis;">Appendix E: Comprehensive Glossary of Cloud-Native and Infrastructure Terminology</td>
      <td style="text-align: right; padding: 4px 0;">478</td>
    </tr>
  </tbody>
</table>
```
