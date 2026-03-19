from math import asin, cos, radians, sin, sqrt


EARTH_RADIUS_METERS = 6371000


def distance_in_meters(
    latitude_1: float,
    longitude_1: float,
    latitude_2: float,
    longitude_2: float,
) -> float:
    delta_latitude = radians(latitude_2 - latitude_1)
    delta_longitude = radians(longitude_2 - longitude_1)

    haversine_value = (
        sin(delta_latitude / 2) ** 2
        + cos(radians(latitude_1))
        * cos(radians(latitude_2))
        * sin(delta_longitude / 2) ** 2
    )
    central_angle = 2 * asin(sqrt(haversine_value))

    return EARTH_RADIUS_METERS * central_angle


def is_within_radius(
    scan_latitude: float,
    scan_longitude: float,
    target_latitude: float,
    target_longitude: float,
    radius_meters: int,
) -> bool:
    distance = distance_in_meters(
        latitude_1=scan_latitude,
        longitude_1=scan_longitude,
        latitude_2=target_latitude,
        longitude_2=target_longitude,
    )
    return distance <= radius_meters
