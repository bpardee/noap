# Build Docker Image for Dev tests:
#
# docker build -f ci/dev.Dockerfile -t noap_dev .
#
ARG ECR_SERVER_URL=""
# Use Elixir 1.17 with OTP 27
FROM ${ECR_SERVER_URL}elixir:1.17.1-otp-27

WORKDIR /opt/noap

# Set environment variables for HEX SSL issues
ENV HEX_NO_CERT_CHECK=1
ENV HEX_UNSAFE_HTTPS=1

COPY . .

# Copy the certificate file if it exists
RUN mkdir -p /opt/ca-certificates
COPY cert.pem /opt/ca-certificates/cert.pem
ENV HEX_CACERTS_PATH=/opt/ca-certificates/cert.pem

RUN echo "===== Install deps for Main app =====" \
  && mix local.hex --force \
  && mix local.rebar --force \
  && mix deps.get

RUN echo "===== Removing _build folder for clean build =====" \
  && rm -rf _build

RUN echo "===== Run Codegen =====" \
  && mix noap.gen.code || echo "Codegen step skipped (no WSDL files to process)"

RUN echo "===== Compile & Run Tests =====" \
  && mix compile \
  && mix test

