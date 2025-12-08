import http from 'k6/http';
import { check, group } from 'k6';
import { Rate } from 'k6/metrics';

// Custom metrics
const createErrors = new Rate('create_errors');
const readErrors = new Rate('read_errors');
const updateErrors = new Rate('update_errors');
const deleteErrors = new Rate('delete_errors');

// Read API endpoint from environment variable
const API_ENDPOINT = __ENV.API_ENDPOINT;
if (!API_ENDPOINT) {
  throw new Error('API_ENDPOINT environment variable is required');
}

// Test configuration
export const options = {
  scenarios: {
    create_load: {
      executor: 'constant-arrival-rate',
      exec: 'testCreate',
      rate: 60,  // 60 requests per minute
      timeUnit: '1m',
      duration: '1m',
      preAllocatedVUs: 10,
      maxVUs: 50,
    },
    read_load: {
      executor: 'constant-arrival-rate',
      exec: 'testRead',
      rate: 120,  // 120 requests per minute
      timeUnit: '1m',
      duration: '1m',
      preAllocatedVUs: 10,
      maxVUs: 50,
      startTime: '1m',  // Start after create test
    },
    update_load: {
      executor: 'constant-arrival-rate',
      exec: 'testUpdate',
      rate: 30,  // 30 requests per minute
      timeUnit: '1m',
      duration: '1m',
      preAllocatedVUs: 5,
      maxVUs: 25,
      startTime: '2m',  // Start after read test
    },
    delete_load: {
      executor: 'constant-arrival-rate',
      exec: 'testDelete',
      rate: 15,  // 15 requests per minute
      timeUnit: '1m',
      duration: '1m',
      preAllocatedVUs: 5,
      maxVUs: 25,
      startTime: '3m',  // Start after update test
    },
  },
  thresholds: {
    'http_req_duration': ['p(95)<2000'], // 95% of requests must complete below 2s
    'http_req_failed': ['rate<0.05'],     // Error rate must be below 5%
    'create_errors': ['rate<0.05'],
    'read_errors': ['rate<0.05'],
    'update_errors': ['rate<0.05'],
    'delete_errors': ['rate<0.05'],
  },
};

// Generate unique IDs
function generateUserId() {
  return `perf-user-${Math.random().toString(36).substring(7)}`;
}

function generateLinkId() {
  return `perf-link-${Date.now()}-${Math.random().toString(36).substring(7)}`;
}

export function testCreate() {
  const userId = generateUserId();
  const linkId = generateLinkId();
  const url = 'https://api.restful-api.dev/objects';

  const payload = JSON.stringify({
    id: linkId,
    url: url,
  });

  const params = {
    headers: {
      'Content-Type': 'application/json',
      'shortener-user-id': userId,
    },
  };

  const res = http.post(`${API_ENDPOINT}/app`, payload, params);
  
  const success = check(res, {
    'CREATE: status is 200': (r) => r.status === 200,
    'CREATE: response has body': (r) => r.body.length > 0,
  });
  
  createErrors.add(!success);
}

export function testRead() {
  const userId = generateUserId();

  const params = {
    headers: {
      'shortener-user-id': userId,
    },
  };

  const res = http.get(`${API_ENDPOINT}/app`, params);
  
  const success = check(res, {
    'READ: status is 200': (r) => r.status === 200,
    'READ: has api version header': (r) => r.headers['Shortener-Api-Rev'] !== undefined,
  });
  
  readErrors.add(!success);
}

export function testUpdate() {
  const userId = generateUserId();
  const linkId = generateLinkId();
  const updatedUrl = 'https://www.example.com/updated';
  const timestamp = new Date().toUTCString();

  const payload = JSON.stringify({
    id: linkId,
    url: updatedUrl,
    timestamp: timestamp,
    owner: userId,
  });

  const params = {
    headers: {
      'Content-Type': 'application/json',
      'shortener-user-id': userId,
    },
  };

  const res = http.put(`${API_ENDPOINT}/app/${linkId}`, payload, params);
  
  const success = check(res, {
    'UPDATE: status is 200 or 400': (r) => r.status === 200 || r.status === 400,
  });
  
  updateErrors.add(!success);
}

export function testDelete() {
  const userId = generateUserId();
  const linkId = generateLinkId();

  const params = {
    headers: {
      'shortener-user-id': userId,
    },
  };

  const res = http.del(`${API_ENDPOINT}/app/${linkId}`, null, params);
  
  const success = check(res, {
    'DELETE: status is 200 or 400': (r) => r.status === 200 || r.status === 400,
  });
  
  deleteErrors.add(!success);
}

export function setup() {
  console.log(`Starting performance tests against: ${API_ENDPOINT}`);
  console.log('Test plan:');
  console.log('  - CREATE: 60 req/min for 1 minute');
  console.log('  - READ:   120 req/min for 1 minute');
  console.log('  - UPDATE: 30 req/min for 1 minute');
  console.log('  - DELETE: 15 req/min for 1 minute');
}

export function teardown(data) {
  console.log('Performance tests completed');
}
