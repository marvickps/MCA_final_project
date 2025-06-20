import logging
import logging.config
import os

# Define the log directory and file
LOG_DIR = os.path.join(os.path.dirname(__file__), '..', '..', 'logs')
LOG_FILE = os.path.join(LOG_DIR, 'app.log')

# Ensure the log directory exists
os.makedirs(LOG_DIR, exist_ok=True)

# Logging configuration
LOGGING_CONFIG = {
    'version': 1,
    \
    'disable_existing_loggers': False,
    'formatters': {
        'standard': {
            'format': '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        },
    },
    'handlers': {
        'file': {
            'level': 'DEBUG',
            'class': 'logging.FileHandler',
            'filename': LOG_FILE,
            'formatter': 'standard',
        },
        'console': {
            'level': 'DEBUG',
            'class': 'logging.StreamHandler',
            'formatter': 'standard',
        },
    },
    'root': {
        'handlers': ['file', 'console'],
        'level': 'DEBUG',
    },
}

# Apply the logging configuration
logging.config.dictConfig(LOGGING_CONFIG)

# Example usage
logger = logging.getLogger(__name__)
logger.info("Logging is configured.")