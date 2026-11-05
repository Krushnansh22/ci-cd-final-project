"""
Counter API Service Test Suite

Test cases can be run with the following:
  nosetests -v --with-spec --spec-color
  coverage report -m
"""
from unittest import TestCase

from service import app
from service.common import status  # HTTP Status Codes
from service.routes import reset_counters


######################################################################
#  T E S T   C A S E S
######################################################################
class CounterTest(TestCase):
    """REST API Server Tests"""

    @classmethod
    def setUpClass(cls):
        """This runs once before the entire test suite"""
        app.testing = True

    @classmethod
    def tearDownClass(cls):
        """This runs once after the entire test suite"""

    def setUp(self):
        """This runs before each test"""
        reset_counters()
        self.app = app.test_client()

    def tearDown(self):
        """This runs after each test"""

    ######################################################################
    #  T E S T   C A S E S
    ######################################################################

    def test_index(self):
        """It should call the index call"""
        resp = self.app.get("/")
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        data = resp.get_json()
        self.assertEqual(data["message"], "Hit Counter Service")
        self.assertEqual(data["version"], "1.0.0")

    def test_health(self):
        """It should be healthy"""
        resp = self.app.get("/health")
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.get_json()["status"], "OK")

    def test_create_counters(self):
        """It should Create a counter"""
        name = "foo"
        resp = self.app.post(f"/counters/{name}")
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        data = resp.get_json()
        self.assertEqual(data["name"], name)
        self.assertEqual(data["counter"], 0)
        # A Location header should point at the new counter
        self.assertIn(f"/counters/{name}", resp.headers["Location"])

    def test_create_duplicate_counter(self):
        """It should not Create a duplicate counter"""
        name = "foo"
        resp = self.app.post(f"/counters/{name}")
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        data = resp.get_json()
        self.assertEqual(data["name"], name)
        self.assertEqual(data["counter"], 0)
        resp = self.app.post(f"/counters/{name}")
        self.assertEqual(resp.status_code, status.HTTP_409_CONFLICT)

    def test_list_counters(self):
        """It should List counters"""
        resp = self.app.get("/counters")
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        data = resp.get_json()
        self.assertEqual(len(data), 0)
        # create a counter and make sure it appears in the list
        self.app.post("/counters/foo")
        resp = self.app.get("/counters")
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        data = resp.get_json()
        self.assertEqual(len(data), 1)

    def test_read_counters(self):
        """It should Read a counter"""
        name = "foo"
        self.app.post(f"/counters/{name}")
        resp = self.app.get(f"/counters/{name}")
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        data = resp.get_json()
        self.assertEqual(data["name"], name)
        self.assertEqual(data["counter"], 0)

    def test_read_missing_counter(self):
        """It should not Read a counter that does not exist"""
        resp = self.app.get("/counters/does-not-exist")
        self.assertEqual(resp.status_code, status.HTTP_404_NOT_FOUND)

    def test_update_counters(self):
        """It should Update a counter"""
        name = "foo"
        resp = self.app.post(f"/counters/{name}")
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        resp = self.app.get(f"/counters/{name}")
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        data = resp.get_json()
        self.assertEqual(data["name"], name)
        self.assertEqual(data["counter"], 0)
        # now update it
        resp = self.app.put(f"/counters/{name}")
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        data = resp.get_json()
        self.assertEqual(data["name"], name)
        self.assertEqual(data["counter"], 1)
        # and again
        resp = self.app.put(f"/counters/{name}")
        self.assertEqual(resp.get_json()["counter"], 2)

    def test_update_missing_counters(self):
        """It should not Update a missing counter"""
        name = "foo"
        resp = self.app.put(f"/counters/{name}")
        self.assertEqual(resp.status_code, status.HTTP_404_NOT_FOUND)

    def test_delete_counters(self):
        """It should Delete a counter"""
        name = "foo"
        # Create a counter
        resp = self.app.post(f"/counters/{name}")
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        # Delete it twice should return the same
        resp = self.app.delete(f"/counters/{name}")
        self.assertEqual(resp.status_code, status.HTTP_204_NO_CONTENT)
        resp = self.app.delete(f"/counters/{name}")
        self.assertEqual(resp.status_code, status.HTTP_204_NO_CONTENT)
        # Get it to make sure it's really gone
        resp = self.app.get(f"/counters/{name}")
        self.assertEqual(resp.status_code, status.HTTP_404_NOT_FOUND)

    def test_method_not_allowed(self):
        """It should reject an unsupported HTTP method"""
        resp = self.app.patch("/counters/foo")
        self.assertEqual(resp.status_code, status.HTTP_405_METHOD_NOT_ALLOWED)

    def test_unknown_route_returns_json(self):
        """It should return a JSON 404 for an unknown route"""
        resp = self.app.get("/this-route-does-not-exist")
        self.assertEqual(resp.status_code, status.HTTP_404_NOT_FOUND)
        data = resp.get_json()
        self.assertEqual(data["error"], "Not Found")
