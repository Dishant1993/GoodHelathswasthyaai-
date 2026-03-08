"""
SwasthyaAI - Comprehensive AWS Architecture Diagram
Single detailed diagram showing all layers and flows
"""

import os
from diagrams import Diagram, Cluster, Edge
from diagrams.aws.general import User, Users
from diagrams.aws.network import APIGateway, CloudFront
from diagrams.aws.storage import S3
from diagrams.aws.security import Cognito, IAM, KMS
from diagrams.aws.compute import Lambda
from diagrams.aws.ml import Transcribe, Comprehend, Bedrock, Translate, Sagemaker
from diagrams.aws.database import Dynamodb, DynamodbTable, RDS
from diagrams.aws.management import Cloudwatch

# Create output directory
os.makedirs("generated-diagrams", exist_ok=True)

print("Generating SwasthyaAI Comprehensive Architecture Diagram...")
print("=" * 70)

with Diagram("SwasthyaAI - AI Powered Clinical Intelligence Platform (AWS Architecture)",
             filename="generated-diagrams/swasthyaai_comprehensive_architecture",
             show=False,
             direction="TB",
             graph_attr={
                 "fontsize": "16",
                 "bgcolor": "white",
                 "pad": "0.5",
                 "ranksep": "1.0",
                 "nodesep": "0.8"
             }):
    
    # ========== USER LAYER ==========
    with Cluster("👥 User Layer", graph_attr={"bgcolor": "#E3F2FD", "style": "rounded"}):
        with Cluster("Users"):
            doctor = User("Doctors\nWeb Dashboard")
            patient = User("Patients\nHealth Summary")
            hospital = User("Hospital EHR\nIntegration")
    
    # ========== API & ACCESS LAYER ==========
    with Cluster("🔐 API & Access Layer", graph_attr={"bgcolor": "#FFF3E0", "style": "rounded"}):
        cdn = CloudFront("CloudFront\nCDN")
        api_gateway = APIGateway("API Gateway\nREST APIs")
        cognito = Cognito("Cognito\nAuthentication\n(MFA)")
    
    # ========== APPLICATION LAYER ==========
    with Cluster("⚙️ Application Layer (Microservices)", graph_attr={"bgcolor": "#F3E5F5", "style": "rounded"}):
        orchestrator = Lambda("Workflow\nOrchestrator")
        
        with Cluster("Microservices"):
            summarization_svc = Lambda("Summarization\nService")
            history_svc = Lambda("History\nService")
            translation_svc = Lambda("Translation\nService")
            alert_svc = Lambda("Alert\nService")
    
    # ========== AI/ML LAYER ==========
    with Cluster("🤖 AI/ML Processing Layer", graph_attr={"bgcolor": "#E8F5E9", "style": "rounded"}):
        with Cluster("Voice & Text Processing"):
            transcribe = Transcribe("Transcribe\nVoice → Text\n(Optional)")
            comprehend = Comprehend("Comprehend\nMedical\nEntity Extraction")
        
        with Cluster("LLM & Intelligence"):
            bedrock = Bedrock("Bedrock\nClaude 3.5\nSummarization\n& Explanation")
            translate = Translate("Translate\nMultilingual\nOutput")
        
        sagemaker = Sagemaker("SageMaker\nFine-tuning\n(Synthetic Data)")
    
    # ========== DATA LAYER ==========
    with Cluster("💾 Data Storage Layer", graph_attr={"bgcolor": "#FCE4EC", "style": "rounded"}):
        with Cluster("Document Storage"):
            s3_clinical = S3("S3\nClinical\nSummaries\n(Encrypted)")
            s3_raw = S3("S3\nRaw Notes\n& Outputs")
        
        with Cluster("Patient History Database"):
            ddb_timeline = DynamodbTable("DynamoDB\nPatient Timeline\nPK: PatientID\nSK: Timestamp")
            ddb_metadata = DynamodbTable("DynamoDB\nPatient Metadata\n& Snapshots")
        
        rds = RDS("RDS\nRelational\nMedical Records\n(Optional)")
    
    # ========== PATIENT HISTORY FEATURE ==========
    with Cluster("📊 Longitudinal Patient History (Key Differentiator)", 
                 graph_attr={"bgcolor": "#FFF9C4", "style": "rounded,bold", "penwidth": "2"}):
        timeline_builder = Lambda("Timeline\nBuilder")
        snapshot_gen = Lambda("Snapshot\nGenerator")
        alert_logic = Lambda("Alert Logic\nAllergies\nChronic Conditions")
        
        with Cluster("Patient Snapshot Components"):
            snapshot_data = Users("• Active Medications\n• Chronic Conditions\n• Recent Vitals\n• Allergies\n• Visit History\n• Risk Alerts")
    
    # ========== SECURITY & COMPLIANCE ==========
    with Cluster("🔒 Security & Compliance Layer", graph_attr={"bgcolor": "#FFEBEE", "style": "rounded"}):
        iam = IAM("IAM\nRole-Based\nAccess Control")
        kms = KMS("KMS\nEncryption\nKeys")
        audit = Cloudwatch("CloudWatch\nAudit Logs\n& Monitoring")
    
    # ========== DATA FLOWS ==========
    
    # User to API
    doctor >> Edge(label="1. Upload Notes/Voice", color="blue") >> cdn
    patient >> Edge(label="View Summary", color="green") >> cdn
    hospital >> Edge(label="EHR Data", color="purple") >> api_gateway
    
    cdn >> api_gateway
    api_gateway >> Edge(label="Authenticate", color="red") >> cognito
    cognito >> Edge(label="Authorized", color="green") >> orchestrator
    
    # Orchestration Flow
    orchestrator >> Edge(label="2. Voice Input", color="blue") >> transcribe
    transcribe >> Edge(label="3. Text Output", color="blue") >> comprehend
    
    orchestrator >> Edge(label="2. Text Input", color="blue") >> comprehend
    
    # AI Processing Flow
    comprehend >> Edge(label="4. Entities:\n• Conditions\n• Medications\n• Dosage\n• Symptoms", color="orange") >> bedrock
    
    bedrock >> Edge(label="5. Structured\nSummary", color="green") >> summarization_svc
    bedrock >> Edge(label="Patient\nExplanation", color="green") >> translation_svc
    
    translation_svc >> translate >> Edge(label="6. Multilingual\nOutput", color="purple") >> s3_clinical
    
    # Data Storage Flow
    summarization_svc >> Edge(label="7. Store\nSummary", color="darkgreen") >> s3_clinical
    summarization_svc >> Edge(label="8. Update\nTimeline", color="darkgreen") >> history_svc
    
    # Patient History Flow
    history_svc >> Edge(label="9. Add Visit\nData", color="brown") >> ddb_timeline
    history_svc >> timeline_builder
    
    timeline_builder >> Edge(label="10. Build\nTimeline", color="brown") >> snapshot_gen
    snapshot_gen >> Edge(label="11. Generate\nSnapshot", color="brown") >> ddb_metadata
    
    # Alert Flow
    history_svc >> Edge(label="Check\nConditions", color="red") >> alert_logic
    alert_logic >> Edge(label="Trigger\nAlerts", color="red") >> ddb_metadata
    
    # Snapshot Data
    ddb_metadata >> Edge(style="dotted", color="gray") >> snapshot_data
    
    # Raw Storage
    comprehend >> Edge(label="Raw Data", color="gray", style="dashed") >> s3_raw
    
    # Optional Fine-tuning
    s3_raw >> Edge(label="Training Data\n(Synthetic)", color="gray", style="dashed") >> sagemaker
    sagemaker >> Edge(label="Fine-tuned\nModel", color="gray", style="dashed") >> bedrock
    
    # Security Connections
    iam - Edge(style="dotted", color="red", label="Authorizes") - orchestrator
    iam - Edge(style="dotted", color="red") - history_svc
    
    kms - Edge(style="dotted", color="green", label="Encrypts") - s3_clinical
    kms - Edge(style="dotted", color="green") - s3_raw
    kms - Edge(style="dotted", color="green") - ddb_timeline
    kms - Edge(style="dotted", color="green") - ddb_metadata
    kms - Edge(style="dotted", color="green") - rds
    
    # Monitoring
    orchestrator >> Edge(style="dotted", color="orange") >> audit
    api_gateway >> Edge(style="dotted", color="orange") >> audit
    history_svc >> Edge(style="dotted", color="orange") >> audit
    
    # Dashboard Display Flow (Return Path)
    ddb_metadata >> Edge(label="12. Retrieve\nSnapshot", color="blue", style="bold") >> history_svc
    s3_clinical >> Edge(label="Retrieve\nSummary", color="blue", style="bold") >> summarization_svc
    
    summarization_svc >> Edge(label="13. Display:\n• Clinical Summary\n• Patient Explanation\n• Longitudinal Snapshot", 
                              color="blue", style="bold") >> api_gateway
    api_gateway >> Edge(label="14. Dashboard", color="blue", style="bold") >> cdn >> doctor

print("\n" + "=" * 70)
print("✅ Comprehensive architecture diagram generated successfully!")
print("\nGenerated file:")
print("  📊 swasthyaai_comprehensive_architecture.png")
print("\nLocation: generated-diagrams/")
print("\nKey Features Highlighted:")
print("  ✓ Layered architecture (User → API → App → AI → Data → Security)")
print("  ✓ Complete data flow with numbered steps")
print("  ✓ Longitudinal patient history as key differentiator")
print("  ✓ Security boundaries and encryption")
print("  ✓ Microservices approach")
print("  ✓ Official AWS icons")
print("  ✓ Color-coded flows")
print("  ✓ Hackathon-ready presentation quality")
print("=" * 70)
