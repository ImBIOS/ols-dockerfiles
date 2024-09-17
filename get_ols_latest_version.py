import requests
from bs4 import BeautifulSoup


def get_latest_openlitespeed_version():
    """
    Scrapes the OpenLiteSpeed downloads page and returns the latest version number.
    """
    url = "https://openlitespeed.org/downloads/"
    response = requests.get(url)
    response.raise_for_status()  # Raise an exception for bad status codes

    soup = BeautifulSoup(response.content, "html.parser")

    # Find the latest version heading (assuming it's the first h6 element)
    latest_version_heading = soup.find("h6")
    if latest_version_heading:
        # Extract the version number from the heading text
        latest_version = latest_version_heading.text.split(" ")[2]
        return latest_version
    else:
        return None


if __name__ == "__main__":
    latest_version = get_latest_openlitespeed_version()
    if latest_version:
        print(f"{latest_version}")
    else:
        # Throw an exception if the latest version could not be found
        raise Exception("Failed to retrieve the latest OpenLiteSpeed version.")
