from configargparse import ArgParser
from multiprocessing import Value
from factoriomcd.rcon import RconConnection
from threading import Thread
from time import sleep
from queue import Queue, Empty

import asyncio
import coloredlogs
import logging
import os


logger = logging.getLogger(__name__)


class LogReaderThread(Thread):
    def __init__(self, options):
        super(LogReaderThread, self).__init__()
        self.options = options
        self.running = Value('b', True)
        self.q = Queue()

    def run(self):
        logger.debug("Booted log reader thread")
        f = open(self.options.log_file)
        file_len = os.stat(self.options.log_file)[6]
        f.seek(file_len)
        pos = f.tell()

        while self.running.value:
            pos = f.tell()
            line = f.readline()
            if not line:
                if os.stat(self.options.log_file)[6] < pos:
                    f.close()
                    f = open(self.options.log_file)
                    pos = f.tell()
                else:
                    sleep(1)
                    f.seek(pos)

            elif line.startswith('##FMC::'):
                logger.debug('Line processed: %s', line)
                self.q.put(line.lstrip('##FMC::'))
            else:
                logger.debug("Line found but not processed: %s", line)

        f.close()


class RconSenderThread(Thread):
    def __init__(self, options):
        super(RconSenderThread, self).__init__()
        self.options = options
        self.running = Value('b', True)
        self.q = Queue()

    @asyncio.coroutine
    def exec_command(self, cmd):
        reconnected = False
        try:
            yield from self.conn.exec_command(cmd)
        except:
            logger.exception("Error")
            while not reconnected and self.running.value:
                try:
                    self.conn = RconConnection(self.options.rcon_host, int(self.options.rcon_port),
                                               self.options.rcon_password)
                    yield from self.conn.exec_command("/silent-command print('FactorioMCd connected.')")
                    yield from self.conn.exec_command("/silent-command print('FactorioMCd connected.')")
                    reconnected = True
                except:
                    sleep(1)

            reconnected = False
            yield from self.conn.exec_command(cmd)

    def run(self):
        logger.debug("Booted rcon sender thread")
        policy = asyncio.get_event_loop_policy()
        policy.set_event_loop(policy.new_event_loop())
        loop = asyncio.get_event_loop()
        self.conn = RconConnection(self.options.rcon_host, int(self.options.rcon_port), self.options.rcon_password)
        resp = loop.run_until_complete(self.conn.exec_command("/silent-command print('FactorioMCd connected.')"))
        resp = loop.run_until_complete(self.conn.exec_command("/silent-command print('FactorioMCd connected.')"))
        while self.running.value:
            try:
                data = self.q.get(timeout=3)
            except Empty:
                data = None

            if not data:
                sleep(1)
            else:
                resp = loop.run_until_complete(self.exec_command(data))
                logger.debug(resp)


class FactorioMCd:
    def __init__(self, options):
        self.options = options

    def run(self):
        self.log = LogReaderThread(self.options)
        self.rcon = RconSenderThread(self.options)

        self.log.start()
        self.rcon.start()

        try:
            self.main_loop()
        except KeyboardInterrupt:
            logger.info("KeyboardInterrupt caught: terminating...")
        finally:
            self.log.running.value = False
            self.rcon.running.value = False

            logger.debug("Stopping log thread")
            self.log.join()
            logger.debug("Stopping rcon thread")
            self.rcon.join()

        logger.info("Terminated.")

    def main_loop(self):
        logger.debug("In main loop")
        while True:
            if self.options.debug:
                import pdb
                pdb.set_trace()

            d = self.log.q.get()
            logger.debug(d)
            sleep(1)


def main():
    parser = ArgParser(default_config_files=['/etc/factoriomcd.ini', '~/.factoriomcd.ini'])
    parser.add('-d', '--debug', action='store_true')
    parser.add('-v', '--verbose', action='store_true')

    parser.add('--log-file', default="/opt/factorio/server.out")

    parser.add('--rcon-host', default="localhost")
    parser.add('--rcon-password', default="asdasd")
    parser.add('--rcon-port', default=31337)

    options = parser.parse_args()
    if options.verbose:
        coloredlogs.install(level='DEBUG')
        logger.debug("FactorioMCd initializing...")
    else:
        coloredlogs.install(level='INFO')

    FactorioMCd(options).run()


if __name__ == "__main__":
    main()
