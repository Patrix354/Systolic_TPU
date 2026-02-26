library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Types.all;

entity Tree_Node is
  generic (
    LINE_NUM : natural := 4;
    MEM_READ_LATENCY : natural := 2
 );
  port (
    i_clk   : in    std_logic;
    i_rstn : in    std_logic;
    i_NoC_ports : in NoC_connect_master_array(LINE_NUM-1 downto 0);
    o_NoC_ports : out NoC_connect_slave_array(LINE_NUM-1 downto 0);
    o_debug : out std_logic_vector(7 downto 0);
    -- Feedback from MAC core
    i_done  : in std_logic    
  );
end entity Tree_Node;

architecture rtl of Tree_Node is
  -- Constants
  constant C_DEFAULT_OUTPUT : NoC_connect_slave := (
    data => (others => '0'),
    ready => '0',
    active => '0',
    read_ready => '0'
  );

  constant C_DEFAULT_INPUT : NoC_connect_master := (
    valid => '0',
    address => (others => '0'),
    data => (others => '0'),
    operation => NoC_NOP
  );

  -- Signals
  signal s_NoC_FSM : NoC_tree_node_state;

  -- Arbiter internal signals
  signal s_reqs : std_logic_vector(LINE_NUM-1 downto 0);
  signal s_higher_pri_reqs : std_logic_vector(LINE_NUM-1 downto 0);
  signal s_grant : std_logic_vector(LINE_NUM-1 downto 0);

  signal s_NoC_process_data_input : NoC_connect_master;
  signal s_NoC_process_data_output : NoC_connect_slave;

  signal s_busy : std_logic;
  signal s_saved_grant : std_logic_vector(LINE_NUM-1 downto 0);
  signal s_internal_register  : std_logic_vector(C_NOC_DATA_WIDTH-1 downto 0);

begin

  -- TODO: Do something with it
  s_internal_register <= (others => '0');

  -- Arbiter logic - generating grant based on requests from each line
  -- Output grant is coded via One-Hot and it's priority fixed (line 0 has the highest priority). 
  gen_reqs : for i in LINE_NUM-1 downto 0 generate
  begin
    s_reqs(i) <= i_NoC_ports(i).valid;
  end generate gen_reqs;

  s_higher_pri_reqs(LINE_NUM-1 downto 1) <= s_higher_pri_reqs(LINE_NUM-2 downto 0) or s_reqs(LINE_NUM-2 downto 0);
  s_higher_pri_reqs(0) <= '0';
  s_grant(LINE_NUM-1 downto 0) <= s_reqs(LINE_NUM-1 downto 0) and (not s_higher_pri_reqs(LINE_NUM-1 downto 0));


  -- Transaction FSM - Responsible for entering and exiting transaction state.
  -- FSM enters transaction state when arbiter sends a request (grant != 0) and isn't pending transaction on diffrent line.
  -- State mashine pushes block to idle state if magic operation was asserted.
  transaction_proc : process (i_clk) is
  begin
    if rising_edge(i_clk) then
      if (i_rstn = '0') then
      
        s_busy <= '0';
        s_NoC_FSM <= NoC_IDLE;
        s_saved_grant <= (others => '0');
        s_NoC_process_data_output.active <= '0';
      
      else
        
        if (unsigned(s_grant) > 0 and s_NoC_FSM = NoC_IDLE) then
          s_busy <= '1';
          s_NoC_process_data_output.active <= '1';
          s_NoC_FSM <= NoC_TRANSACTION;
          s_saved_grant <= s_grant;
        elsif (s_NoC_FSM = NoC_TRANSACTION and s_NoC_process_data_input.operation = NoC_END and s_NoC_process_data_input.valid = '1' and s_NoC_process_data_output.ready = '1') then
          s_busy <= '0';
          s_NoC_process_data_output.active <= '0';
          s_NoC_FSM <= NoC_IDLE;
          s_saved_grant <= (others => '0');
        else
          s_busy <= s_busy;
          s_NoC_process_data_output.active <= s_NoC_process_data_output.active;
          s_NoC_FSM <= s_NoC_FSM;
          s_saved_grant <= s_saved_grant;
        end if;
      
      end if;
    end if;
  end process transaction_proc;

  -- Mulitplex logic: processes inputs based on grant signal 
  -- Internal signals for NoC are connected to apropriate line
  mux_proc : process( all ) is
  begin
      s_NoC_process_data_input <= C_DEFAULT_INPUT;
      
      mux_loop : for i in LINE_NUM-1 downto 0 loop
        if(s_saved_grant(i) = '1' and s_NoC_FSM = NoC_TRANSACTION) then
          s_NoC_process_data_input <= i_NoC_ports(i);
          o_NoC_ports(i) <= s_NoC_process_data_output;
        else
          o_NoC_ports(i) <= C_DEFAULT_OUTPUT;
        end if;
      end loop ; -- identifier

  end process mux_proc; 

  --  Decoder FSM : Translates inconing NoC operations
  decode_proc : process(i_clk) is 
  begin
      if rising_edge(i_clk) then
        if (i_rstn = '0') then
          o_debug <= X"00";
          s_NoC_process_data_output.data <= X"0000";
          s_NoC_process_data_output.ready <= '0';
          s_NoC_process_data_output.read_ready <= '0';
        else
          if(s_NoC_process_data_input.operation = NoC_WRITE and s_NoC_process_data_input.valid = '1' and s_NoC_process_data_output.ready = '1') then
            o_debug <= X"01";
            s_NoC_process_data_output.data <= X"0101";
            s_NoC_process_data_output.ready <= '1';
            s_NoC_process_data_output.read_ready <= '0';
            -- TODO: Perform SRAM write operation
          elsif (s_NoC_process_data_input.operation = NoC_READ and s_NoC_process_data_input.valid = '1' and s_NoC_process_data_output.ready = '1') then
            -- TODO: Perform SRAM read operation
            o_debug <= X"02";
            s_NoC_process_data_output.data <= X"0202";
            s_NoC_process_data_output.ready <= '1';
            s_NoC_process_data_output.read_ready <= '1';
          elsif (s_NoC_process_data_input.operation = NoC_EXECUTE and s_NoC_process_data_input.valid = '1' and s_NoC_process_data_output.ready = '1') then
            -- TODO: Perform execute sequence
            o_debug <= X"03";
            s_NoC_process_data_output.data <= X"0303";
            s_NoC_process_data_output.ready <= '1';
            s_NoC_process_data_output.read_ready <= '0';
          elsif (s_NoC_process_data_input.operation = NoC_NOP and s_NoC_process_data_input.valid = '1' and s_NoC_process_data_output.ready = '1') then
            -- TODO: Perform NOP
            s_NoC_process_data_output.data <= X"0404";
            s_NoC_process_data_output.ready <= '1';
            s_NoC_process_data_output.read_ready <= '0';
            o_debug <= X"04";
          else 
            o_debug <= X"05";
            s_NoC_process_data_output.data <= X"0505";
            s_NoC_process_data_output.ready <= '1';
            s_NoC_process_data_output.read_ready <= '0';
          end if;             
        end if;
    end if;
  end process decode_proc;

end architecture rtl;
