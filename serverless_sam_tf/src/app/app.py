import json
import logging
from typing import Any, Dict
import requests

from aws_lambda_powertools.utilities.typing import LambdaContext
from aws_lambda_powertools.utilities.data_classes import event_source, APIGatewayProxyEvent


logger = logging.getLogger()
logger.setLevel(logging.INFO)

@event_source(data_class=APIGatewayProxyEvent)
def handler(event: APIGatewayProxyEvent, context: LambdaContext) -> Dict[str, Any]:
    try:
        logger.info("About to get current ip address ...")
        ip = requests.get("http://checkip.amazonaws.com/")
    except requests.RequestException as e:
        logger.exception("Unable to figure out ip address.")
        raise e
    
    return {
        "statusCode": 200, 
        "headers": {
            "headerName1": "headerValue1",
            "headerName2": "headerValue2"
        },
        "body": ip.text.replace("\n", "")
    }