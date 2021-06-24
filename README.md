# Enhancing Applications

In this project, you will apply the skills you have acquired in the Azure Performance course to collect and display performance and health data about an application. This is only half the battle; the other half is making informed decisions about the data and automating remediation tasks. You will use a combination of cloud technologies, such as Azure Kubernetes Service, VM Scale Sets, Application Insights, Azure Log Analytics, and Azure Runbooks to showcase your skills in diagnosing and rectifying application and infrastructure problems.

In this project, you'll be tasked to do the following:

- Setup Application Insights monitoring on a VMSS and implement monitoring in an application to collect telemetry data
- Setup an auto-scaling for a VMSS
- Setup an Azure Automation account and create a RunBook to automate the resolution of performance issues
- Create alerts to trigger auto-scaling on an AKS cluster and trigger a RunBook to execute

# Part 1. Getting Started

### Prerequisites 
1. [Create a free Azure Account](https://azure.microsoft.com/en-us/free/)
2. [Create a free Azure DevOps account](https://azure.microsoft.com/en-us/pricing/details/devops/azure-devops-services/) (Click **Start Free** under **Azure Pipelines**)
3. [VS Code or your preferred editor](https://code.visualstudio.com/Download) Install the VS Code extensions for Python (optional)
4. [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)

### Dependencies to run the application locally
- [Python](https://www.python.org/downloads/)
- Redis server (Instructions are available below). 

### Required Python Packages
All these packages below are mentioned in the *requirements.txt* that you can use during the **Local Environment Setup**. 
```bash
Flask==1.1.2
opencensus==0.7.13
opencensus-ext-azure==1.0.4
opencensus-ext-flask==0.7.3
redis==3.5.3
```

---

# Part 2. Local Environment Setup (Optional)

If you want to run the application on localhost, follow the next steps; otherwise, you can skip to the **Azure Environment Setup** section next. 


1. **Install Redis** - Download and install Redis server for your operating system: [Linux](https://redis.io/download), [MacOS](https://medium.com/@petehouston/install-and-config-redis-on-mac-os-x-via-homebrew-eb8df9a4f298), or [Windows](https://riptutorial.com/redis/example/29962/installing-and-running-redis-server-on-windows)

2. **Start Redis** - Start and verify the Redis server:
```bash
# Mac
redis-server /usr/local/etc/redis.conf
# Linux
redis-server
# Windows - Navigate to the Redis folder, and run
redis-server.exe
redis-cli.exe
# Ping your Redis server to verify if it is running. It will return "PONG"
redis-cli ping
```

3. **Create a Virtual Environment** (Optional) - It's your choice to work in a virtual environment. For this, you must have the [virtualenv](https://virtualenv.pypa.io/en/latest/installation.html#via-pip) installed. Then, create and activate a virtual environment:
```bash
# Navigate to the azure-vote/ folder 
cd azure-vote/
```
```bash
# Mac/Linux
python3 -m venv .venv 
source .venv/bin/activate
# Windows on Powershell or GitBash terminal
py -3 -m venv .venv
.venv\Scripts\activate
```

4. **Dependencies** - Install dependencies from *requirements.txt*:
```bash
# Run this command from the parent directory where you have the requirements.txt file
pip install -r requirements.txt
``` 

5. Run the application:
```bash
python main.py
```

>**NOTE**: The statement `app.run()` in `/azure-vote/main.py` file is currently set for your local environment. Replace it with the following statement when deploying the application to a VM Scale Set:
>```py
>app.run(host='0.0.0.0', threaded=True, debug=True)
>```

---

# Part 3. Azure Environment Setup

### Azure VM Scale Set

A bash script has been provided to automate the creation of the VMSS. You should not need to modify this script.

**Note**: You'll need [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) installed before using this script.

1. Log in to Azure using `az login`.
2. Run `./setup-script.sh` in your terminal.

The script will take a few minutes to create and configure all resources. Once the script is complete, you can go to Azure portal and look for the **acdnd-c4-project** resource group. Inside is the VMSS resource. You'll use the public IP address and port 50000 to connect to the VM. It's port 50000 because the inbound NAT rule of the load balancer defaults to port 50000.

The following command will connect you to your VM. **Note**: Replace `[public-ip]` with the public-ip address of your VMSS.

`ssh -p 50000 udacityadmin@[public-ip]`

### Setup Azure Pipeline to Deploy to VM Scale Set

We'll use Azure Pipelines to deploy our application to an Azure VM Scale Set. Follow the step-by-step instructions [here](azure-pipelines-instructions.md).

## Project Instructions

### Application Insights & Log Analytics

1. Create a Log Analytics workspace resource
2. Create an Application Insights resource and use the Log Analytics workspace created in step 1
3. Enable Application Insights monitoring for the VM Scale Set
4. Add the reference Application Insights to `main.py` and specify the instrumentation key
5. Add custom event telemetry when 'Dogs' is clicked and when 'Cats' is clicked.
6. Create a query to view the event telemetry in Log Analytics.
7. Create a chart from query showing when 'Dogs' or 'Cats' is clicked.

### Monitoring Containers

1. Run `az login` to login, then run `./create-cluster.sh` to create an AKS cluster and deploy a container to it.
2. Once that is completed, go to Insights for the cluster.
3. Observe the state of the cluster. Note the number of nodes and number of containers.
4. Create an alert in Azure Monitor to trigger when the number of pods increases over a certain threshold.
5. Create an autoscaler by using the following Azure CLI command—`kubectl autoscale deployment azure-vote-front --cpu-percent=70 --min=1 --max=10`
6. Cause load on the system
7. After approximately 10 minutes, stop the load.
8. Observe the state of the cluster. Note the number of pods; it should have increased and should now be decreasing.

### Autoscaling

1. For the VM Scale Set, create an autoscaling rule based on metrics.
2. Trigger the conditions for the rule, causing an autoscaling event.
3. When complete, enable manual scale.

### Runbook

1. Create an Azure Automation Account
2. Create a Runbook—either using a script or the UI—that will remedy a problem.
3. Create an alert which uses a runbook to remedy a problem.
4. Cause the problem to the flask app on the VM Scale Set.
5. Verify the problem is remedied via the Runbook.

## Submissions

1. The `main.py` which will show the code for the Application Insights telemety data.
2. Screenshots for the kubernetes cluster which include:
   **Note**: Place all screenshots for Kubernetes Cluster in the `submission-screenshots/kubernetes-cluster` directory
   - The output of the Horizontal Pod Autoscaler, showing an increase in the number of pods.
   - The Application Insights metrics which show the increase in the number of pods.
   - The email you received from the alert when the pod count increased.
3. Screenshots for the Application Insights which include:
   **Note**: Place all screenshots for Application Insights in the `submission-screenshots/application-insights` directory
   - The metrics from the VM Scale Set instance--this will show CPU %, Available Memory %, Information about the Disk, and information about the bytes sent and received. There will be 7 graphs which display this data.
   - Application Insight Events which show the results of clicking 'vote' for each 'Dogs' & 'Cats'
   - The output of the `traces` query in Azure Log Analytics.
   - The chart created from the output of the `traces` query.
4. Screenshots for the Autoscaling of the VM Scale Set which include:
   **Note**: Place all screenshots for Autoscaling VMSS in the `submission-screenshots/autoscaling-vmss` directory
   - The conditions for which autoscaling will be triggered (found in the 'Scaling' item in the VM Scale Set).
   - The Activity log of the VM scale set which shows that it scaled up with timestamp.
   - The new instances being created.
   - The metrics which show the load increasing, then decreasing once scaled up with timestamp.
5. Screenshots for the Azure Runbook which include:
   **Note**: Place all screenshots for RunBook in the `submission-screenshots/runbook` directory
   - The alert configuration in Azure Monitor which shows the resource, condition, action group (this should include a reference to your Runbook), and alert rule details (may need 2 screenshots).
   - The email you received from the alert when the Runbook was executed.
   - The summary of the alert which shows 'why did this alert fire?', timestamps, and the criterion in which it fired.

## Built With

### Software

- [Python](https://www.python.org/downloads/) - Programming Language
- [VS Code](https://code.visualstudio.com/) - Integrated Development Environment
- [Azure DevOps](https://dev.azure.com) - Source control and pipeline creation tool.

### Open-source 3rd-party

- [Azure Voting App](https://github.com/Azure-Samples/azure-voting-app-redis) - Container and sample python flask app.
- [Redis](https://redis.io/) - In memory database used for caching.

## License

[License](./LICENSE.md)

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
