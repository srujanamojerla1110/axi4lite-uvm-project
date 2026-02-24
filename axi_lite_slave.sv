module axi_lite_slave #(
    parameter int ADDR_WIDTH = 4,
    parameter int DATA_WIDTH = 32,
    parameter int NUM_REGS = 4
  
)(
    input  logic                     ACLK,
    input  logic                     ARESETN,

    // Write address channel
    input  logic [ADDR_WIDTH-1:0]    AWADDR,
    input  logic                     AWVALID,
    output logic                     AWREADY,

    // Write data channel
    input  logic [DATA_WIDTH-1:0]    WDATA,
    input  logic                     WVALID,
    output logic                     WREADY,

    // Write response channel
    output logic [1:0]               BRESP,
    output logic                     BVALID,
    input  logic                     BREADY,

    // Read address channel
    input  logic [ADDR_WIDTH-1:0]    ARADDR,
    input  logic                     ARVALID,
    output logic                     ARREADY,

    // Read data channel
    output logic [DATA_WIDTH-1:0]    RDATA,
    output logic [1:0]               RRESP,
    output logic                     RVALID,
    input  logic                     RREADY
);

    //---------------------------------------------
    // Register File
    //---------------------------------------------
  logic [DATA_WIDTH-1:0] regfile [0:NUM_REGS-1];

    //---------------------------------------------
    // Internal Signals
    //---------------------------------------------
    logic [ADDR_WIDTH-1:0] awaddr_reg;
    logic [DATA_WIDTH-1:0] wdata_reg;
    logic aw_done, w_done;

    logic [ADDR_WIDTH-1:0] araddr_reg;
    logic ar_done;

    //---------------------------------------------
    // Address decode
    //---------------------------------------------
    logic addr_valid_write;
    logic addr_valid_read;

    assign addr_valid_write = (awaddr_reg[3:2] < 4);
    assign addr_valid_read  = (araddr_reg[3:2] < 4);

    //---------------------------------------------
    // WRITE CHANNEL
    //---------------------------------------------
    always_ff @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            AWREADY <= 0;
            WREADY  <= 0;
            BVALID  <= 0;
            BRESP   <= 2'b00;
            aw_done <= 0;
            w_done  <= 0;
        end
        else begin

            // Address handshake
            if (AWVALID && !aw_done) begin
                AWREADY   <= 1;
                awaddr_reg <= AWADDR;
                aw_done   <= 1;
            end
            else begin
                AWREADY <= 0;
            end

            // Data handshake
            if (WVALID && !w_done) begin
                WREADY    <= 1;
                wdata_reg <= WDATA;
                w_done    <= 1;
            end
            else begin
                WREADY <= 0;
            end

            // Perform write
            if (aw_done && w_done && !BVALID) begin
                if (addr_valid_write) begin
                    regfile[awaddr_reg[3:2]] <= wdata_reg;
                    BRESP <= 2'b00;
                end
                else begin
                    BRESP <= 2'b10;
                end

                BVALID  <= 1;
                aw_done <= 0;
                w_done  <= 0;
            end

            // Response handshake
            if (BVALID && BREADY)
                BVALID <= 0;
        end
    end

    //---------------------------------------------
    // READ CHANNEL
    //---------------------------------------------
    always_ff @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            ARREADY <= 0;
            RVALID  <= 0;
            RRESP   <= 0;
            RDATA   <= 0;
            ar_done <= 0;
        end
        else begin

            // Address handshake
            if (ARVALID && !ar_done) begin
                ARREADY   <= 1;
                araddr_reg <= ARADDR;
                ar_done   <= 1;
            end
            else begin
                ARREADY <= 0;
            end

            // Provide data
            if (ar_done && !RVALID) begin
                if (addr_valid_read) begin
                    RDATA <= regfile[araddr_reg[3:2]];
                    RRESP <= 2'b00;
                end
                else begin
                    RDATA <= 32'hDEADBEEF;
                    RRESP <= 2'b10;
                end

                RVALID <= 1;
                ar_done <= 0;
            end

            // Read handshake
            if (RVALID && RREADY)
                RVALID <= 0;
        end
    end

endmodule
