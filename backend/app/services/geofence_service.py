from app.utils.geo import distance_in_meters, is_within_radius


class GeofenceService:
    def distance_in_meters(
        self,
        latitude_1: float,
        longitude_1: float,
        latitude_2: float,
        longitude_2: float,
    ) -> float:
        return distance_in_meters(
            latitude_1=latitude_1,
            longitude_1=longitude_1,
            latitude_2=latitude_2,
            longitude_2=longitude_2,
        )

    def is_within_radius(
        self,
        scan_latitude: float,
        scan_longitude: float,
        target_latitude: float,
        target_longitude: float,
        radius_meters: int,
    ) -> bool:
        return is_within_radius(
            scan_latitude=scan_latitude,
            scan_longitude=scan_longitude,
            target_latitude=target_latitude,
            target_longitude=target_longitude,
            radius_meters=radius_meters,
        )


geofence_service = GeofenceService()

