-- --------------------------------------------------------
-- Conceptual Database Schema for
-- Automated Mould Detection & Housing Analytics
-- --------------------------------------------------------

-- Table: Dim_Property_Types
-- Description: Lookup table for different types of properties (e.g., House, Flat, Maisonette).
CREATE TABLE Dim_Property_Types (
    PropertyTypeID SERIAL PRIMARY KEY, -- Or INTEGER PRIMARY KEY AUTOINCREMENT for SQLite
    PropertyTypeName VARCHAR(100) UNIQUE NOT NULL,
    Description TEXT
);

-- Table: Dim_Construction_Materials
-- Description: Lookup table for primary construction materials (e.g., Brick, Timber Frame, Concrete).
CREATE TABLE Dim_Construction_Materials (
    MaterialID SERIAL PRIMARY KEY,
    MaterialName VARCHAR(100) UNIQUE NOT NULL,
    Description TEXT
);

-- Table: Dim_Regions
-- Description: Lookup table for geographical regions or operational areas.
CREATE TABLE Dim_Regions (
    RegionID SERIAL PRIMARY KEY,
    RegionName VARCHAR(100) UNIQUE NOT NULL,
    RegionalManager VARCHAR(150)
);

-- Table: Dim_Surveyors
-- Description: Information about surveyors conducting inspections.
CREATE TABLE Dim_Surveyors (
    SurveyorID VARCHAR(50) PRIMARY KEY, -- Could be an employee ID
    FirstName VARCHAR(100) NOT NULL,
    LastName VARCHAR(100) NOT NULL,
    Email VARCHAR(255) UNIQUE,
    PhoneNumber VARCHAR(20),
    Team VARCHAR(100)
);

-- Table: Dim_Tenants
-- Description: Basic, anonymized or pseudonymized tenant information for vulnerability analysis.
-- NB: Handle PII with extreme care and according to data protection regulations (GDPR, etc.).
-- Consider if this level of detail is necessary or if aggregated vulnerability scores are sufficient.
CREATE TABLE Dim_Tenants (
    TenantID VARCHAR(50) PRIMARY KEY, -- Pseudonymized ID
    HouseholdSize INTEGER,
    VulnerabilityScore INTEGER, -- Calculated score (e.g., 1-10) based on various factors
    VulnerabilityFactors TEXT, -- Comma-separated list of contributing factors (e.g., elderly, young_children, health_condition)
    JoinedDate DATE
    -- Avoid storing direct PII like names, specific ages, precise health conditions here unless absolutely necessary and secured.
);

-- Table: Fact_Properties
-- Description: Core table for property details.
CREATE TABLE Fact_Properties (
    PropertyID VARCHAR(50) PRIMARY KEY, -- Unique property reference number
    AddressLine1 VARCHAR(255) NOT NULL,
    AddressLine2 VARCHAR(255),
    City VARCHAR(100),
    Postcode VARCHAR(10) NOT NULL,
    RegionID INTEGER,
    PropertyTypeID INTEGER,
    ConstructionMaterialID INTEGER,
    YearBuilt INTEGER,
    NumberOfBedrooms INTEGER,
    NumberOfBathrooms INTEGER,
    SquareFootage DECIMAL(10, 2),
    EPC_Rating CHAR(1), -- Energy Performance Certificate Rating (A-G)
    LastMajorRefurbishmentDate DATE,
    CurrentTenantID VARCHAR(50), -- FK to Dim_Tenants (if tracking current occupancy)
    Latitude DECIMAL(9, 6), -- For mapping
    Longitude DECIMAL(9, 6), -- For mapping
    DateAddedToStock DATE,
    LastKnownMouldRiskScore INTEGER, -- Overall risk score for the property (1-5, updated periodically)
    IsDecentHomesStandard BOOLEAN, -- Compliance with Decent Homes Standard
    Notes TEXT,
    FOREIGN KEY (RegionID) REFERENCES Dim_Regions(RegionID),
    FOREIGN KEY (PropertyTypeID) REFERENCES Dim_Property_Types(PropertyTypeID),
    FOREIGN KEY (ConstructionMaterialID) REFERENCES Dim_Construction_Materials(MaterialID),
    FOREIGN KEY (CurrentTenantID) REFERENCES Dim_Tenants(TenantID)
);
CREATE INDEX idx_properties_postcode ON Fact_Properties(Postcode);
CREATE INDEX idx_properties_region ON Fact_Properties(RegionID);

-- Table: Fact_Inspections
-- Description: Records of property inspections.
CREATE TABLE Fact_Inspections (
    InspectionID VARCHAR(50) PRIMARY KEY,
    PropertyID VARCHAR(50) NOT NULL,
    SurveyorID VARCHAR(50),
    InspectionDate DATE NOT NULL,
    InspectionType VARCHAR(100), -- e.g., Routine, Damp & Mould, Post-Repair
    OverallConditionAssessment TEXT,
    ReportPath VARCHAR(255), -- Path to the full inspection report document
    ScheduledDate DATE,
    CompletedTimestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (PropertyID) REFERENCES Fact_Properties(PropertyID),
    FOREIGN KEY (SurveyorID) REFERENCES Dim_Surveyors(SurveyorID)
);
CREATE INDEX idx_inspections_property_date ON Fact_Inspections(PropertyID, InspectionDate);

-- Table: Fact_Images
-- Description: Metadata for images captured during inspections.
CREATE TABLE Fact_Images (
    ImageID VARCHAR(50) PRIMARY KEY, -- Could be a UUID
    InspectionID VARCHAR(50) NOT NULL,
    ImagePath VARCHAR(255) NOT NULL UNIQUE, -- Path to image file (e.g., S3 URL, network path)
    ImageTimestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    RoomLocation VARCHAR(100), -- e.g., Kitchen, Bathroom, Bedroom 1
    SpecificLocationDetail TEXT, -- e.g., Ceiling above window, Corner wall
    UploaderID VARCHAR(50), -- Could be SurveyorID or system ID
    ResolutionWidth INTEGER,
    ResolutionHeight INTEGER,
    FileSizeKB INTEGER,
    Notes TEXT,
    FOREIGN KEY (InspectionID) REFERENCES Fact_Inspections(InspectionID)
);
CREATE INDEX idx_images_inspection ON Fact_Images(InspectionID);

-- Table: Dim_ML_Models
-- Description: Information about the machine learning models used for predictions.
CREATE TABLE Dim_ML_Models (
    ModelID SERIAL PRIMARY KEY,
    ModelName VARCHAR(100) NOT NULL, -- e.g., VGG16-Mould-Detector
    ModelVersion VARCHAR(20) NOT NULL,
    Description TEXT,
    TrainingDate DATE,
    Accuracy DECIMAL(5,4), -- e.g. 0.9850
    Precision DECIMAL(5,4),
    Recall DECIMAL(5,4),
    F1Score DECIMAL(5,4),
    UNIQUE (ModelName, ModelVersion)
);

-- Table: Fact_Mould_Predictions
-- Description: Stores predictions made by the ML models on images.
CREATE TABLE Fact_Mould_Predictions (
    PredictionID VARCHAR(50) PRIMARY KEY, -- Could be a UUID
    ImageID VARCHAR(50) NOT NULL,
    ModelID INTEGER NOT NULL,
    PredictionTimestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PredictedClass VARCHAR(50) NOT NULL, -- e.g., 'Mould', 'NoMould', 'Uncertain'
    ConfidenceScore DECIMAL(5,4) NOT NULL, -- Probability (0.0 to 1.0)
    TrueLabel VARCHAR(50), -- If available from manual verification for model retraining/monitoring
    VerificationTimestamp TIMESTAMP,
    VerifierID VARCHAR(50),
    FOREIGN KEY (ImageID) REFERENCES Fact_Images(ImageID),
    FOREIGN KEY (ModelID) REFERENCES Dim_ML_Models(ModelID),
    FOREIGN KEY (VerifierID) REFERENCES Dim_Surveyors(SurveyorID)
);
CREATE INDEX idx_predictions_image ON Fact_Mould_Predictions(ImageID);
CREATE INDEX idx_predictions_model_timestamp ON Fact_Mould_Predictions(ModelID, PredictionTimestamp);

-- Table: Fact_Reported_Issues (from tenants or other sources, distinct from inspections)
-- Description: Tracks issues reported by tenants or other means.
CREATE TABLE Fact_Reported_Issues (
    ReportedIssueID VARCHAR(50) PRIMARY KEY,
    PropertyID VARCHAR(50) NOT NULL,
    TenantID VARCHAR(50),
    ReportedDate DATE NOT NULL,
    IssueType VARCHAR(100) NOT NULL, -- e.g., Damp, Mould, Leak, Structural
    Description TEXT NOT NULL,
    Severity VARCHAR(50), -- e.g., Low, Medium, High, Critical
    Status VARCHAR(50) DEFAULT 'Open', -- e.g., Open, In Progress, Resolved, Closed
    ResolutionDate DATE,
    SourceOfReport VARCHAR(100), -- e.g., Tenant Call, Online Portal, Staff Observation
    FOREIGN KEY (PropertyID) REFERENCES Fact_Properties(PropertyID),
    FOREIGN KEY (TenantID) REFERENCES Dim_Tenants(TenantID)
);
CREATE INDEX idx_reported_issues_property ON Fact_Reported_Issues(PropertyID);

-- Table: Fact_Remediation_Actions
-- Description: Tracks actions taken to remediate mould or other issues.
CREATE TABLE Fact_Remediation_Actions (
    ActionID VARCHAR(50) PRIMARY KEY,
    PropertyID VARCHAR(50) NOT NULL,
    InspectionID VARCHAR(50), -- Link to inspection that identified the need
    ReportedIssueID VARCHAR(50), -- Link to a tenant-reported issue
    ActionType VARCHAR(150) NOT NULL, -- e.g., Mould Wash, Repaint, Ventilation Install, Plaster Repair
    ActionScheduledDate DATE,
    ActionStartDate DATE,
    ActionCompletionDate DATE,
    Cost DECIMAL(10, 2),
    Contractor VARCHAR(150),
    Status VARCHAR(50) DEFAULT 'Pending', -- e.g., Pending, In Progress, Completed, Cancelled
    FollowUpRequired BOOLEAN DEFAULT FALSE,
    FollowUpDate DATE,
    Notes TEXT,
    FOREIGN KEY (PropertyID) REFERENCES Fact_Properties(PropertyID),
    FOREIGN KEY (InspectionID) REFERENCES Fact_Inspections(InspectionID),
    FOREIGN KEY (ReportedIssueID) REFERENCES Fact_Reported_Issues(ReportedIssueID)
);
CREATE INDEX idx_remediation_property ON Fact_Remediation_Actions(PropertyID);

-- Table: Fact_Tenant_Feedback
-- Description: Stores feedback from tenants post-remediation or generally.
CREATE TABLE Fact_Tenant_Feedback (
    FeedbackID VARCHAR(50) PRIMARY KEY,
    PropertyID VARCHAR(50) NOT NULL,
    TenantID VARCHAR(50),
    ActionID VARCHAR(50), -- Link to remediation action if feedback is specific to it
    FeedbackDate DATE NOT NULL,
    SatisfactionScore INTEGER, -- e.g., 1-5
    Comments TEXT,
    Channel VARCHAR(50), -- e.g., Survey, Phone Call, Email
    FOREIGN KEY (PropertyID) REFERENCES Fact_Properties(PropertyID),
    FOREIGN KEY (TenantID) REFERENCES Dim_Tenants(TenantID),
    FOREIGN KEY (ActionID) REFERENCES Fact_Remediation_Actions(ActionID)
);

-- --------------------------------------------------------
-- Data Insertion Examples (Illustrative)
-- --------------------------------------------------------

-- INSERT INTO Dim_Property_Types (PropertyTypeName, Description) VALUES
-- ('Terraced House', 'A house built as part of a continuous row in a uniform style.'),
-- ('Semi-Detached House', 'A house joined to one other house by a common wall.'),
-- ('Detached House', 'A stand-alone residential structure.'),
-- ('Flat/Apartment', 'A self-contained housing unit that is part of a larger building.');

-- INSERT INTO Dim_Regions (RegionName, RegionalManager) VALUES
-- ('North London', 'Jane Doe'),
-- ('South East', 'John Smith');

-- INSERT INTO Dim_ML_Models (ModelName, ModelVersion, Description, TrainingDate, Accuracy, Precision, Recall, F1Score) VALUES
-- ('VGG16-Mould-Detector', '1.0', 'Initial VGG16 based model for mould detection', '2023-05-01', 0.9810, 0.9750, 0.9880, 0.9815),
-- ('EfficientNetB0-Mould', '1.1', 'Optimized model using EfficientNetB0', '2023-10-15', 0.9850, 0.9820, 0.9890, 0.9855);

-- --------------------------------------------------------
-- Consider adding more lookup tables (Dimensions) as needed:
-- Dim_Contractors, Dim_Issue_Types, Dim_Action_Status, etc.
-- Consider temporal tables or history tables if tracking changes to property details over time is critical.
-- --------------------------------------------------------