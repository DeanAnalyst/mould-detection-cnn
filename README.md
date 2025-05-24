# Automated Mould Detection CNN Model

This repository contains the Python (TensorFlow/Keras) code for a Convolutional Neural Network (CNN) designed to detect mould in property images. This work formed a significant part of my MSc in Data Science & Analytics dissertation.

**For a comprehensive overview of the project, including the problem statement, methodology, conceptual integration with SQL and Power BI, and potential business impact, please visit the detailed project page on my portfolio:**
➡️ [Dean Bonsu - Mould Detection Project](https://DeanAnalyst.github.io/projects/mould-detection/) ⬅️

## Overview

The model leverages transfer learning with the VGG-16 architecture to classify images as either containing mould or being clean. It includes data augmentation, training, evaluation, and Class Activation Maps (CAMs) for model interpretability.

## Repository Structure

- **/notebooks/** or **/python_code/**:
  - `mould_detection_vgg16.ipynb`: Jupyter Notebook containing the complete workflow: data loading, augmentation, model definition, training, evaluation, and CAM generation.
- **/sql_schema/**:
  - `conceptual_schema.sql`: DDL for a conceptual relational database schema to store model predictions and related housing data.
- **/dissertation/**:
  - `UP2091348_Dissertation.pdf`: The full MSc dissertation document.
- **/models/**: (If you include pre-trained models)
  - `vgg-16Model_originalMod.h5`: Example of a saved model file.
- **/data_samples/**: (Optional)
  - A small subset of images for quick testing or demonstration if the full dataset is too large to include.
- **/test images for mould/**: (Optional)
  - Sample images used for prediction and CAM generation in the notebook.

## Technical Stack

- Python 3.x
- TensorFlow & Keras
- NumPy, Matplotlib, Scikit-learn, OpenCV (cv2)
- Jupyter Notebook

## Setup & Usage

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/DeanAnalyst/mould-detection-cnn.git
    cd mould-detection-cnn
    ```
2.  **Set up a Python environment** (e.g., using conda or venv) and install the required libraries:
    ```bash
    pip install tensorflow keras numpy matplotlib scikit-learn opencv-python jupyter
    ```
3.  **(Data)** If the full dataset is not included, download it from [Source - if applicable, or state "Dataset was privately compiled for dissertation from public images"] and place it in a `data/MouldImages/` directory structure as expected by the notebook (`train/mould`, `train/clean`, `test/mould`, `test/clean`).
4.  **Run the Jupyter Notebook:**
    ```bash
    jupyter notebook notebooks/mould_detection_vgg16.ipynb
    ```
    Execute the cells to see the data processing, model training, and evaluation.

## Key Features Implemented

- Image data loading and preprocessing.
- Data augmentation to improve model robustness.
- Transfer learning with VGG-16.
- Model training and saving the best performing model.
- Evaluation using accuracy, loss curves, and confusion matrix.
- Prediction on new images.
- Class Activation Maps (CAMs) for visualizing model attention.

---

_This project primarily focuses on the machine learning aspect. The SQL and Power BI components are conceptualized as part of a broader, end-to-end solution._
