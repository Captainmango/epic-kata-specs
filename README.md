# Language Learning Test Suites

A collection of end-to-end (E2E) test suites designed to assist in learning programming languages through hands-on projects. Each test suite validates that your implementation meets the specified requirements.

## How It Works

1. **Pick a Project** – Choose a test suite from the list below
2. **Build the Project** – Implement the project in your chosen programming language
3. **Run the Tests** – Execute the test suite against your implementation to verify it passes

## Available Test Suites

| Project | Description | Test Framework | Difficulty |
|---------|-------------|----------------|------------|
| [coco-task](./coco-task) | A task manager API with scheduling capabilities | [Hurl](https://hurl.dev) | Medium (depending on approach) |
| [coco-dealer](./coco-dealer) | A card dealing service for managing decks and game rooms | [Hurl](https://hurl.dev) | Medium |
| [blogga](./blogga) | A blogging platform API for managing posts and comments | [Hurl](https://hurl.dev) | Easy |

## Prerequisites

- [Hurl](https://hurl.dev) – A command line tool for running HTTP requests and tests

### Installing Hurl

**macOS:**
```bash
brew install hurl
```

**Linux:**
```bash
curl --location --remote-name https://github.com/Orange-OpenSource/hurl/releases/download/4.3.0/hurl_4.3.0_amd64.deb
sudo dpkg -i hurl_4.3.0_amd64.deb
```

**Windows:**
```powershell
choco install hurl
```

For other installation methods, see the [official Hurl documentation](https://hurl.dev/docs/installation.html).

## Usage

Each test suite includes a shell script to run the tests. Navigate to the project directory and execute the runner script.

### Example: Running the coco-task Tests

```bash
cd coco-task
./run-hurl-tests.sh [host]
```

**Arguments:**
- `host` (optional) – The base URL of your running application. Defaults to `http://localhost:3000`

**Environment Variables:**
- `HURL_HOST` – Can be used instead of the command line argument to specify the host

## Resources

- [Hurl Documentation](https://hurl.dev/docs/index.html)
- [Cron Expression Format](https://en.wikipedia.org/wiki/Cron)
