import logging
import os
from datetime import timedelta
from typing import Optional

from cachelib.file import FileSystemCache
from celery.schedules import crontab
from cachelib.redis import RedisCache

logger = logging.getLogger()

LOGO_TARGET_PATH = '/'
APP_NAME = "Mainstay Analytics"

FAVICONS = [{ "href":"https://d15jbbxs3h1fzs.cloudfront.net/favicon-16x16.png"}]

APP_ICON = "https://d15jbbxs3h1fzs.cloudfront.net/mainstay-logo-horiz.png"

EXTRA_CATEGORICAL_COLOR_SCHEMES = [
     {
        "id": 'mainstayDark',
        "description": '',
         "label": 'Mainstay Dark',
        "isDefault": False,
        "colors":
    ['#092E63',
      '#DF2C55',
      '#039855',
      '#FEC84B',
      '#1D2939',
      '#CB271B',
      '#FCC700',
      '#620B3E',
      '#00FFD4',
      '#00E0FF']

    },
    {
        "id": 'mainstayPastel',
        "description": '',
         "label": 'Mainstay Pastel',
        "isDefault": False,
        "colors":
      ['#FCCDD7',
      '#E7EBF0',
      '#D1FADF',
      '#FFF0C8',
      '#D0D5DD',
      '#FEE4E2',
      '#FFFCF5',
      '#F4A0D2',
      '#CCFFF6',
      '#BFF7FF',
    ]
    },
         {
        "id": 'mainstayFull',
        "description": '',
         "label": 'Mainstay Fullcolor',
        "isDefault": True,
        "colors":
      ['#092E63',
      '#DF2C55',
      '#039855',
      '#FEC84B',
      '#1D2939',
      '#CB271B',
      '#FCC700',
      '#620B3E',
      '#00FFD4',
      '#00E0FF',
      '#FCCDD7',
      '#E7EBF0',
      '#D1FADF',
      '#FFF0C8',
      '#D0D5DD',
      '#FEE4E2',
      '#FFFCF5',
      '#F4A0D2',
      '#CCFFF6',
      '#BFF7FF',
    ]
    }]


def get_env_variable(var_name: str, default: Optional[str] = None) -> str:
    """Get the environment variable or raise exception."""
    try:
        return os.environ[var_name]
    except KeyError:
        if default is not None:
            return default
        else:
            error_msg = "The environment variable {} was missing, abort...".format(
                var_name
            )
            raise EnvironmentError(error_msg)

## Data Amounts

# default row limit when requesting chart data
ROW_LIMIT = 1000000
# default row limit when requesting samples from datasource in explore view
SAMPLES_ROW_LIMIT = 150
# max rows retrieved by filter select auto complete
FILTER_SELECT_ROW_LIMIT = 10000
DATABASE_DIALECT = get_env_variable("DATABASE_DIALECT")
DATABASE_USER = get_env_variable("DATABASE_USER")
DATABASE_PASSWORD = get_env_variable("DATABASE_PASSWORD")
DATABASE_HOST = get_env_variable("DATABASE_HOST")
DATABASE_PORT = get_env_variable("DATABASE_PORT")
DATABASE_DB = get_env_variable("DATABASE_DB")

SECRET_KEY = get_env_variable("SECRET_KEY")

# The SQLAlchemy connection string.
SQLALCHEMY_DATABASE_URI = "%s://%s:%s@%s:%s/%s" % (
    DATABASE_DIALECT,
    DATABASE_USER,
    DATABASE_PASSWORD,
    DATABASE_HOST,
    DATABASE_PORT,
    DATABASE_DB,
)

REDIS_HOST = get_env_variable("REDIS_HOST")
REDIS_PORT = get_env_variable("REDIS_PORT")
REDIS_CELERY_DB = get_env_variable("REDIS_CELERY_DB", "1")
REDIS_RESULTS_DB = get_env_variable("REDIS_RESULTS_DB", "2")
REDIS_CACHE_DB = get_env_variable("REDIS_RESULTS_DB", "3")

RESULTS_BACKEND = FileSystemCache("/app/superset_home/sqllab")

class CeleryConfig(object):
    BROKER_URL = f"redis://{REDIS_HOST}:{REDIS_PORT}/{REDIS_CELERY_DB}"
    CELERY_IMPORTS = ("superset.sql_lab", "superset.tasks")
    CELERY_RESULT_BACKEND = f"redis://{REDIS_HOST}:{REDIS_PORT}/{REDIS_RESULTS_DB}"
    CELERYD_LOG_LEVEL = "DEBUG"
    CELERYD_PREFETCH_MULTIPLIER = 1
    CELERY_ACKS_LATE = False
    CELERYBEAT_SCHEDULE = {
        "reports.scheduler": {
            "task": "reports.scheduler",
            "schedule": crontab(minute="*", hour="*"),
        },
        "reports.prune_log": {
            "task": "reports.prune_log",
            "schedule": crontab(minute=10, hour=0),
        },
    }


CELERY_CONFIG = CeleryConfig
RESULTS_BACKEND = RedisCache(
    host=REDIS_HOST, port=REDIS_PORT, key_prefix='superset_results')

FEATURE_FLAGS = {"ALERT_REPORTS": True,
                 "DASHBOARD_RBAC": True,
                     "DASHBOARD_NATIVE_FILTERS": True,
                "DASHBOARD_CROSS_FILTERS": True,
                "DASHBOARD_NATIVE_FILTERS_SET": True,
                "DASHBOARD_FILTERS_EXPERIMENTAL": True,
                "GLOBAL_ASYNC_QUERIES": True,
                "EMBEDDED_SUPERSET": True}

# TODO: Should we add the other caches?
FILTER_STATE_CACHE_CONFIG = {
    "CACHE_TYPE": "redis",
    "CACHE_REDIS_HOST": REDIS_HOST,
    "CACHE_REDIS_PORT": REDIS_PORT,
    "CACHE_REDIS_DB": REDIS_CACHE_DB,
}
EXPLORE_FORM_DATA_CACHE_CONFIG = {
    "CACHE_TYPE": "redis",
    "CACHE_REDIS_HOST": REDIS_HOST,
    "CACHE_REDIS_PORT": REDIS_PORT,
    "CACHE_REDIS_DB": REDIS_CACHE_DB,
}

ALERT_REPORTS_NOTIFICATION_DRY_RUN = True
WEBDRIVER_BASEURL = "http://superset:8088/"
# The base URL for the email report hyperlinks.
WEBDRIVER_BASEURL_USER_FRIENDLY = WEBDRIVER_BASEURL

SQLLAB_CTAS_NO_LIMIT = True

#
# Optionally import superset_config_docker.py (which will have been included on
# the PYTHONPATH) in order to allow for local settings to be overridden
#
try:
    import superset_config_docker
    from superset_config_docker import *  # noqa

    logger.info(
        f"Loaded your Docker configuration at " f"[{superset_config_docker.__file__}]"
    )
except ImportError:
    logger.info("Using default Docker config...")
