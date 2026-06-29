# \# R.A.D.A.R.

# \### Real-time Airline Detection and Analytics for Risk

# 

# An end-to-end airline payment fraud detection pipeline built on a 3 million row synthetic dataset. The project spans data engineering, exploratory analysis, feature engineering, and machine learning model development — from raw transaction ingestion to a trained fraud classifier.

# 

# \---

# 

# \## Overview

# 

# Airline payment fraud presents unique detection challenges: high transaction velocity, multinational card issuance, diverse booking channels, and a severe class imbalance where fraud represents a small fraction of total volume. RADAR is designed to address these challenges through domain-aware feature engineering and gradient boosting models trained specifically on airline payment patterns.

# 

# The pipeline currently achieves \*\*96% recall on the fraud class\*\* using a CatBoost classifier with balanced class weighting.

# 

# \---

# 

# \## Dataset

# 

# The dataset is synthetic, generated to reflect realistic airline payment fraud characteristics across three fraud topologies:

# 

# \- \*\*Account Takeover\*\* — compromised credentials used to book on legitimate accounts

# \- \*\*Card Testing\*\* — low-value probe transactions used to validate stolen card details

# \- \*\*Checkout Abuse\*\* — fraudulent bookings using stolen payment instruments at checkout

# 

# The dataset contains 3 million rows hosted on HuggingFace Hub in Parquet format.

# 

# \*\*HuggingFace:\*\* `analytical-community/airline\_fraud\_transactions`

# 

# \---

# 

# \## Repository Structure

# 

# ```

# airline-fraud-radar/

# │

# ├── eda\_modelling.ipynb       # Core notebook: ingestion, EDA, features, modelling

# ├── requirements.txt          # Python dependencies

# └── README.md

# ```

# 

# \---

# 

# \## Pipeline

# 

# \### 1. Data Ingestion

# Data is read directly from HuggingFace Hub using `HfFileSystem` into a pandas DataFrame via PyArrow. No local download required.

# 

# \### 2. Exploratory Data Analysis

# \- Overall fraud rate: \*\*1.5%\*\* of transactions

# \- Revenue loss quantified after USD normalization across currencies

# \- Categorical risk profiles by card type, BIN country, and issuing bank

# \- Hourly fraud distribution analysis — no significant midnight/odd-hour spikes observed

# 

# \### 3. Feature Engineering

# 

# | Feature | Description |

# | :--- | :--- |

# | `device\_id\_last\_24h` | Rolling count of transactions from the same device in the past 24 hours |

# | `total\_cards\_ip\_7d` | Distinct card BINs seen from the same IP address in the past 7 days |

# | `country\_mismatch` | Binary flag where BIN country differs from transaction origin country |

# | `domain\_risk\_score` | Risk tier derived from email domain transaction volume |

# | `account\_age\_risk\_score` | Risk tier based on account age: new (<1 day), recent (1-30 days), established (>30 days) |

# 

# \### 4. Modelling

# 

# \*\*Model 1: CatBoost — Balanced Weighting Run\*\*

# 

# \- 60% train / 20% validation / 20% test split

# \- `auto\_class\_weights='Balanced'` to handle class imbalance without oversampling

# \- Early stopping on validation set (50 rounds)

# \- GPU acceleration supported

# \- Top drivers: geographical features and issuer-specific signals

# 

# \*\*Model 2:\*\* In development.

# 

# \---

# 

# \## Results

# 

# | Metric | Fraud Class (1) |

# | :--- | :--- |

# | Recall | 96% |

# | False Positives | \~4,646 (controlled trade-off) |

# 

# The model is configured to prioritize fraud catch-rate over precision. False positives are treated as transactions flagged for manual review rather than outright declines.

# 

# \---

# 

# \## Tech Stack

# 

# | Layer | Libraries |

# | :--- | :--- |

# | Data I/O | `pandas`, `pyarrow`, `huggingface\_hub` |

# | Visualization | `matplotlib`, `seaborn`, `plotly` |

# | Preprocessing | `scikit-learn`, `imbalanced-learn` |

# | Modelling | `catboost`, `xgboost`, `scikit-learn` |

# | Environment | `python-dotenv` |

# 

# \---

# 

# \## Setup

# 

# \*\*1. Clone the repository\*\*

# ```bash

# git clone https://github.com/0xsquawk/airline-fraud-radar.git

# cd airline-fraud-radar

# ```

# 

# \*\*2. Install dependencies\*\*

# ```bash

# pip install -r requirements.txt

# ```

# 

# \*\*3. Configure HuggingFace authentication\*\*

# 

# Create a `.env` file in the project root:

# ```

# hugging\_token=your\_hf\_token\_here

# ```

# 

# \*\*4. Run the notebook\*\*

# ```bash

# jupyter notebook eda\_modelling.ipynb

# ```

# 

# A GPU is recommended for the CatBoost training cell. The `task\_type="GPU"` parameter is active by default — remove or comment it out if running on CPU only.

# 

# \---

# 

# \## Authors

# 

# | Author | Role |

# | :--- | :--- |

# | Charchit (@0xSquawk) | Data Ingestion, EDA, Model Development |

# | Priyanka | Feature Engineering |

# 

# \---

# 

# \## License

# 

# This project uses a fully synthetic dataset. No real passenger, payment, or airline data is included.

