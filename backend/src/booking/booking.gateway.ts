import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Logger } from '@nestjs/common';

@WebSocketGateway({
  cors: {
    origin: '*',
  },
})
export class BookingGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(BookingGateway.name);

  handleConnection(client: Socket) {
    this.logger.log(`Client connected: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    this.logger.log(`Client disconnected: ${client.id}`);
  }

  @SubscribeMessage('join_room')
  handleJoinRoom(client: Socket, payload: { room: string }) {
    if (payload && payload.room) {
      client.join(payload.room);
      this.logger.log(`Client ${client.id} joined room: ${payload.room}`);
      return { event: 'joined', data: payload.room };
    }
  }

  @SubscribeMessage('leave_room')
  handleLeaveRoom(client: Socket, payload: { room: string }) {
    if (payload && payload.room) {
      client.leave(payload.room);
      this.logger.log(`Client ${client.id} left room: ${payload.room}`);
      return { event: 'left', data: payload.room };
    }
  }

  // Broadcasts a new booking to all eligible technicians and notifies admin
  broadcastNewBooking(booking: any, eligibleTechnicianIds: string[]) {
    this.logger.log(`[BookingGateway] broadcastNewBooking: Booking ID: ${booking.id}, Eligible Technicians Count: ${eligibleTechnicianIds.length}`);
    
    // Task 1: Print the exact event name emitted for new bookings
    const eventName = 'booking_created';
    this.logger.log(`[BookingGateway] Exact event name to emit: "${eventName}"`);

    // Emit booking_created event to the specific rooms of eligible technicians
    for (const techId of eligibleTechnicianIds) {
      // Task 2: Print the exact Socket.IO room name used
      const roomName = `technician_${techId}`;
      const roomSockets = this.server.sockets.adapter.rooms.get(roomName);
      const socketCount = roomSockets ? roomSockets.size : 0;

      this.logger.log(`[BookingGateway] Emit Attempt: eventName="${eventName}", targetRoom="${roomName}", socketCount=${socketCount}`);
      this.logger.log(`[BookingGateway] Payload: ${JSON.stringify(booking)}`);

      try {
        // Task 4 & 5: Emit and verify success
        const emitResult = this.server.to(roomName).emit(eventName, booking);
        if (emitResult) {
          this.logger.log(`[BookingGateway] Successfully called emit for "${eventName}" to room "${roomName}". Sockets notified count: ${socketCount}`);
        } else {
          this.logger.warn(`[BookingGateway] Emit returned falsy result for room "${roomName}"`);
        }
      } catch (error) {
        this.logger.error(`[BookingGateway] Error emitting "${eventName}" to room "${roomName}":`, error);
      }
    }

    // Emit booking_status_updated globally to notify general listeners (like the admin dashboard)
    this.logger.log(`[BookingGateway] Emitting "booking_status_updated" globally for booking ID: ${booking.id}`);
    this.server.emit('booking_status_updated', {
      bookingId: booking.id,
      status: 'WAITING_FOR_TECHNICIAN',
    });
  }

  // Broadcasts booking acceptance and removal events
  broadcastBookingAccepted(
    bookingId: string,
    bookingLocalId: string | null,
    technicianName: string,
    technicianPhone: string,
    technicianBranch: string,
    technicianDisplayId: string,
  ) {
    this.logger.log(`Broadcasting booking accepted: ${bookingId} (localId: ${bookingLocalId}) by ${technicianName}`);

    // Notify all online technicians to remove this job from their available feed
    this.server.to('online_technicians').emit('booking_accepted', {
      bookingId,
      technicianName,
    });

    const rooms = [`booking_${bookingId}`];
    if (bookingLocalId) {
      rooms.push(`booking_${bookingLocalId}`);
    }

    for (const room of rooms) {
      this.server.to(room).emit('booking_status_updated', {
        bookingId,
        status: 'TECHNICIAN_ASSIGNED',
        technicianName,
        technicianPhone,
        technicianBranch,
        technicianId: technicianDisplayId,
      });
    }

    // Notify general updates (admin dashboard) globally
    this.server.emit('booking_status_updated', {
      bookingId,
      status: 'TECHNICIAN_ASSIGNED',
    });
  }

  // Broadcasts general booking status updates
  broadcastBookingStatusUpdated(
    bookingId: string,
    bookingLocalId: string | null,
    status: string,
    technicianName?: string,
    technicianPhone?: string,
    technicianBranch?: string,
    technicianDisplayId?: string,
  ) {
    this.logger.log(`Broadcasting booking status update: ${bookingId} (localId: ${bookingLocalId}) -> ${status}`);

    const rooms = [`booking_${bookingId}`];
    if (bookingLocalId) {
      rooms.push(`booking_${bookingLocalId}`);
    }

    for (const room of rooms) {
      this.server.to(room).emit('booking_status_updated', {
        bookingId,
        status,
        technicianName,
        technicianPhone,
        technicianBranch,
        technicianId: technicianDisplayId,
      });
    }

    // Notify general updates (admin dashboard) globally
    this.server.emit('booking_status_updated', {
      bookingId,
      status,
    });
  }
}
